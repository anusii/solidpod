#!/usr/bin/env python3
"""Headless load tester for a Community Solid Server (CSS v7+).

Copyright (C) 2026, Software Innovation Institute, ANU.

Licensed under the GNU General Public License, Version 3 (the "License").

License: https://opensource.org/license/gpl-3-0.

This program is free software: you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation, either version 3 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
details.

You should have received a copy of the GNU General Public License along with
this program.  If not, see <https://opensource.org/license/gpl-3-0>.

Authors: Tony Chen

This script stress-tests Pod hosting, login and read/write access at scale
(up to ~100 concurrent users). For each simulated user it exercises the full
lifecycle against the target server:

  1. Create an account            (CSS account JSON API)
  2. Create a Pod                 (CSS account JSON API)
  3. Optionally change password   (CSS account JSON API)
  4. Issue client credentials     (CSS account JSON API)
  5. Log in for an access token   (OAuth client_credentials grant + DPoP)
  6. Create a security key        (per-user passphrase + derived AES key)
  7. Write resources             (authenticated PUT, optionally encrypted)
  8. Read resources back          (authenticated GET, decrypt and verify)

The account-management flow mirrors solidpod's `css_account_api.dart`. The
authenticated read/write flow uses the CSS client-credentials + DPoP mechanism
because the solidpod/solidui libraries only support interactive (browser) OIDC
login, which does not scale to a hundred automated users.

The "security key" generated here plays the same role as solidpod's master key:
a per-user passphrase from which a symmetric key is derived and used to encrypt
resource content before it is written, then to decrypt it on read. The on-Pod
key format is deliberately simpler than solidpod's (this tester targets the
server, not the library), so encrypted resources written here are not intended
to be read back by the Flutter app.

The example app drives this script and parses its output, so when invoked with
`--json` every progress update is emitted as a single line of JSON on stdout
(JSON Lines). Without `--json` the output is human-readable for standalone use.

Usage (standalone):

    python3 solid_load_test.py --server https://solid.dev.empwr.au \
        --users 100 --concurrency 20 --resources 3

Requirements: see requirements.txt (httpx, cryptography).
"""

from __future__ import annotations

import argparse
import asyncio
import base64
import hashlib
import json
import os
import secrets
import sys
import time
from dataclasses import dataclass, field
from typing import Any
from urllib.parse import quote

import httpx
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import ec, utils as asym_utils
from cryptography.hazmat.primitives.ciphers.aead import AESGCM
from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2HMAC

# ---------------------------------------------------------------------------
# Output helpers
#
# When the example app launches this script it passes `--json`, so progress is
# emitted as JSON Lines (one JSON object per line). The `_emit()` helper is the
# single choke point for all output so the human-readable and machine-readable
# modes never drift apart.
# ---------------------------------------------------------------------------

_JSON_MODE = False


def _emit(event: str, **fields: Any) -> None:
    """Emit a single progress event to stdout.

    In JSON mode each event is a compact one-line JSON object; otherwise a
    short human-readable line is printed. stdout is flushed after every event
    so the launching app sees progress in real time rather than in a buffered
    burst at the end.
    """

    record = {'event': event, **fields}
    if _JSON_MODE:
        sys.stdout.write(json.dumps(record, separators=(',', ':')) + '\n')
    else:
        sys.stdout.write(_humanise(record) + '\n')
    sys.stdout.flush()


def _humanise(record: dict[str, Any]) -> str:
    """Render an event as a readable line for standalone (non-JSON) runs."""

    event = record['event']
    if event == 'start':
        return (f"Starting load test: {record['users']} users, "
                f"concurrency {record['concurrency']}, server {record['server']}")
    if event == 'phase':
        status = record['status'].upper()
        ms = record.get('ms')
        suffix = f" ({ms} ms)" if ms is not None else ''
        detail = f" - {record['detail']}" if record.get('detail') else ''
        return (f"  [user {record['user']:>3}] {record['step']:<17} "
                f"{status}{suffix}{detail}")
    if event == 'user_done':
        outcome = 'OK' if record['ok'] else 'FAILED'
        return (f"[user {record['user']:>3}] {record['email']} -> {outcome} "
                f"({record['total_ms']} ms)")
    if event == 'progress':
        return (f"Progress: {record['completed']}/{record['total']} "
                f"(ok {record['ok']}, failed {record['failed']})")
    if event == 'summary':
        return _humanise_summary(record)
    if event == 'error':
        return f"ERROR: {record.get('message', '')}"
    return json.dumps(record)


def _humanise_summary(s: dict[str, Any]) -> str:
    lines = [
        '',
        '=' * 60,
        'LOAD TEST SUMMARY',
        '=' * 60,
        f"Server               : {s['server']}",
        f"Users requested      : {s['users']}",
        f"Users succeeded      : {s['users_ok']}",
        f"Users failed         : {s['users_failed']}",
        f"Resources written    : {s['resources_written']}",
        f"Resources read back  : {s['resources_read']}",
        f"Wall-clock time      : {s['wall_ms']} ms",
        '',
        'Per-step timing (ms): mean / p95 / max  [failures]',
    ]
    for step, st in s['steps'].items():
        if st['count'] == 0 and st['failures'] == 0:
            continue
        lines.append(
            f"  {step:<17} {st['mean']:>7} / {st['p95']:>7} / {st['max']:>7}"
            f"  [{st['failures']}]"
        )
    lines.append('=' * 60)
    return '\n'.join(lines)


# ---------------------------------------------------------------------------
# DPoP (Demonstration of Proof-of-Possession)
#
# CSS issues DPoP-bound access tokens for the client_credentials grant, so every
# token request and every authenticated resource request must carry a freshly
# signed DPoP proof JWT. We sign with a per-user EC P-256 key. PyJWT is avoided
# so the only third-party crypto dependency is `cryptography`.
# ---------------------------------------------------------------------------


def _b64url(data: bytes) -> str:
    """Base64url-encode without padding (as required by JOSE)."""

    return base64.urlsafe_b64encode(data).rstrip(b'=').decode('ascii')


class DpopKey:
    """A per-user EC key pair used to sign DPoP proofs."""

    def __init__(self) -> None:
        self._key = ec.generate_private_key(ec.SECP256R1())
        numbers = self._key.public_key().public_numbers()
        # The public JWK is embedded in every proof header; CSS uses its
        # thumbprint to bind the issued access token to this key.
        self.jwk = {
            'kty': 'EC',
            'crv': 'P-256',
            'x': _b64url(numbers.x.to_bytes(32, 'big')),
            'y': _b64url(numbers.y.to_bytes(32, 'big')),
        }

    def proof(
        self,
        method: str,
        url: str,
        *,
        nonce: str | None = None,
        access_token: str | None = None,
    ) -> str:
        """Build a signed DPoP proof JWT for a single request.

        [nonce] is supplied on retry after the server answers with a
        `DPoP-Nonce` header. [access_token] is supplied for resource requests so
        the proof carries the `ath` (access-token hash) claim binding it to the
        token in use.
        """

        header = {'typ': 'dpop+jwt', 'alg': 'ES256', 'jwk': self.jwk}
        payload: dict[str, Any] = {
            'htu': url,
            'htm': method,
            'jti': _b64url(secrets.token_bytes(16)),
            'iat': int(time.time()),
        }
        if nonce is not None:
            payload['nonce'] = nonce
        if access_token is not None:
            digest = hashlib.sha256(access_token.encode('ascii')).digest()
            payload['ath'] = _b64url(digest)

        signing_input = (
            _b64url(json.dumps(header, separators=(',', ':')).encode())
            + '.'
            + _b64url(json.dumps(payload, separators=(',', ':')).encode())
        )
        der_sig = self._key.sign(
            signing_input.encode('ascii'), ec.ECDSA(hashes.SHA256()))
        # JOSE wants the raw r||s concatenation, not the ASN.1/DER form that
        # `cryptography` returns.
        r, s = asym_utils.decode_dss_signature(der_sig)
        raw_sig = r.to_bytes(32, 'big') + s.to_bytes(32, 'big')
        return signing_input + '.' + _b64url(raw_sig)


# ---------------------------------------------------------------------------
# Per-user security key + encryption
#
# Mirrors the intent of solidpod's master key: a random passphrase is generated
# for the user, an AES-256 key is derived from it via PBKDF2, and resource
# content is sealed with AES-GCM before upload then opened again on read.
# ---------------------------------------------------------------------------


@dataclass
class SecurityKey:
    """A generated security key and the symmetric key derived from it."""

    passphrase: str
    salt: bytes
    aes_key: bytes

    @classmethod
    def generate(cls) -> 'SecurityKey':
        passphrase = secrets.token_urlsafe(24)
        salt = secrets.token_bytes(16)
        kdf = PBKDF2HMAC(
            algorithm=hashes.SHA256(), length=32, salt=salt, iterations=100_000)
        aes_key = kdf.derive(passphrase.encode('utf-8'))
        return cls(passphrase=passphrase, salt=salt, aes_key=aes_key)

    def encrypt(self, plaintext: str) -> bytes:
        """Seal [plaintext] as nonce || ciphertext for upload."""

        nonce = secrets.token_bytes(12)
        sealed = AESGCM(self.aes_key).encrypt(
            nonce, plaintext.encode('utf-8'), None)
        return nonce + sealed

    def decrypt(self, blob: bytes) -> str:
        """Open content sealed by [encrypt]."""

        nonce, sealed = blob[:12], blob[12:]
        opened = AESGCM(self.aes_key).decrypt(nonce, sealed, None)
        return opened.decode('utf-8')


# ---------------------------------------------------------------------------
# Timing + result accounting
# ---------------------------------------------------------------------------

# The ordered set of steps each simulated user runs through. Kept as a list so
# the summary reports timings in lifecycle order.
STEP_NAMES = [
    'create_account',
    'create_pod',
    'change_password',
    'client_credentials',
    'login_token',
    'security_key',
    'write',
    'read',
]


@dataclass
class UserResult:
    """Outcome and per-step timings for a single simulated user."""

    index: int
    email: str
    ok: bool = False
    total_ms: int = 0
    resources_written: int = 0
    resources_read: int = 0
    # step name -> (milliseconds, failed?)
    timings: dict[str, tuple[int, bool]] = field(default_factory=dict)


class _Step:
    """Context manager that times a lifecycle step and emits its result.

    A raised exception is recorded as a failure for the step, re-emitted as a
    `phase` event, then propagated so the caller can abort the rest of that
    user's lifecycle.
    """

    def __init__(self, result: UserResult, name: str) -> None:
        self.result = result
        self.name = name
        self._start = 0.0

    def __enter__(self) -> '_Step':
        self._start = time.monotonic()
        return self

    def __exit__(self, exc_type, exc, tb) -> bool:
        ms = int((time.monotonic() - self._start) * 1000)
        failed = exc_type is not None
        self.result.timings[self.name] = (ms, failed)
        _emit(
            'phase',
            user=self.result.index,
            step=self.name,
            status='error' if failed else 'ok',
            ms=ms,
            detail=str(exc) if failed else None,
        )
        # Do not suppress the exception; the caller handles user-level abort.
        return False


# ---------------------------------------------------------------------------
# CSS account JSON API + authenticated resource access
# ---------------------------------------------------------------------------

_GET_HEADERS = {'Accept': 'application/json'}
_POST_HEADERS = {'Accept': 'application/json', 'Content-Type': 'application/json'}


class CssClient:
    """A thin async client over one CSS server for a single simulated user."""

    def __init__(self, client: httpx.AsyncClient, server: str) -> None:
        self._http = client
        self._server = server.rstrip('/')
        self._account_index = f'{self._server}/.account/'
        self.dpop = DpopKey()
        self.access_token: str | None = None
        self._dpop_nonce: str | None = None

    # -- Account management (mirrors css_account_api.dart) ------------------

    async def _controls(
        self, token: str | None = None) -> dict[str, Any]:
        """Fetch the account index and return its `controls` object.

        Without [token] only the logged-out controls (login, account.create)
        are present; with an account token the account-scoped controls (pod,
        clientCredentials, password.create) appear as well.
        """

        headers = dict(_GET_HEADERS)
        if token is not None:
            headers['Authorization'] = f'CSS-Account-Token {token}'
        resp = await self._http.get(self._account_index, headers=headers)
        if resp.status_code != 200:
            raise RuntimeError(
                f'account index HTTP {resp.status_code}: {resp.text[:200]}')
        return resp.json().get('controls', {})

    async def create_account(self, email: str, password: str) -> str:
        """Create a bare account and register an email/password login.

        Returns the account authorization token used for the remaining
        account-scoped calls.
        """

        controls = await self._controls()
        create_url = controls.get('account', {}).get('create')
        if not create_url:
            raise RuntimeError('server does not expose account.create (CSS v7+ required)')

        resp = await self._http.post(create_url, headers=_POST_HEADERS, json={})
        if not 200 <= resp.status_code < 300:
            raise RuntimeError(
                f'account create HTTP {resp.status_code}: {resp.text[:200]}')
        token = resp.json().get('authorization')
        if not token:
            raise RuntimeError('account create returned no authorization token')

        # Register the email/password login on the new account.
        auth_controls = await self._controls(token)
        password_create = auth_controls.get('password', {}).get('create')
        if not password_create:
            raise RuntimeError('server does not expose password.create')
        resp = await self._http.post(
            password_create,
            headers={**_POST_HEADERS, 'Authorization': f'CSS-Account-Token {token}'},
            json={'email': email, 'password': password},
        )
        if resp.status_code in (400, 409):
            raise RuntimeError(f'email "{email}" already registered')
        if not 200 <= resp.status_code < 300:
            raise RuntimeError(
                f'password create HTTP {resp.status_code}: {resp.text[:200]}')
        return token

    async def create_pod(self, token: str, pod_name: str) -> str:
        """Provision a Pod under the account and return its base URL."""

        controls = await self._controls(token)
        pod_url = controls.get('account', {}).get('pod')
        if not pod_url:
            raise RuntimeError('server does not expose account.pod')
        resp = await self._http.post(
            pod_url,
            headers={**_POST_HEADERS, 'Authorization': f'CSS-Account-Token {token}'},
            json={'name': pod_name},
        )
        if not 200 <= resp.status_code < 300:
            raise RuntimeError(
                f'pod create HTTP {resp.status_code}: {resp.text[:200]}')
        url = resp.json().get('url') or f'{self._server}/{pod_name}/'
        return url if url.endswith('/') else url + '/'

    async def change_password(
        self, token: str, email: str, old_password: str, new_password: str) -> None:
        """Change the account password via the account JSON API."""

        controls = await self._controls(token)
        logins_url = controls.get('password', {}).get('create')
        if not logins_url:
            raise RuntimeError('server does not expose password login controls')
        auth = {'Authorization': f'CSS-Account-Token {token}'}
        resp = await self._http.get(logins_url, headers={**_GET_HEADERS, **auth})
        if resp.status_code != 200:
            raise RuntimeError(
                f'list logins HTTP {resp.status_code}: {resp.text[:200]}')
        logins = resp.json().get('passwordLogins', {})
        resource = next(
            (v for k, v in logins.items() if k.lower() == email.lower()), None)
        if not resource:
            raise RuntimeError(f'no password login found for "{email}"')
        resp = await self._http.post(
            resource,
            headers={**_POST_HEADERS, **auth},
            json={'oldPassword': old_password, 'newPassword': new_password},
        )
        if not 200 <= resp.status_code < 300:
            raise RuntimeError(
                f'change password HTTP {resp.status_code}: {resp.text[:200]}')

    async def issue_client_credentials(
        self, token: str, web_id: str, label: str) -> tuple[str, str]:
        """Create a client-credentials token and return (id, secret)."""

        controls = await self._controls(token)
        cc_url = controls.get('account', {}).get('clientCredentials')
        if not cc_url:
            raise RuntimeError('server does not expose account.clientCredentials')
        resp = await self._http.post(
            cc_url,
            headers={**_POST_HEADERS, 'Authorization': f'CSS-Account-Token {token}'},
            json={'name': label, 'webId': web_id},
        )
        if not 200 <= resp.status_code < 300:
            raise RuntimeError(
                f'client credentials HTTP {resp.status_code}: {resp.text[:200]}')
        body = resp.json()
        return body['id'], body['secret']

    # -- Login (client_credentials grant + DPoP) ---------------------------

    async def _token_endpoint(self) -> str:
        """Discover the OIDC token endpoint from the server metadata."""

        url = f'{self._server}/.well-known/openid-configuration'
        resp = await self._http.get(url, headers=_GET_HEADERS)
        if resp.status_code != 200:
            raise RuntimeError(
                f'openid-configuration HTTP {resp.status_code}')
        endpoint = resp.json().get('token_endpoint')
        if not endpoint:
            raise RuntimeError('server metadata has no token_endpoint')
        return endpoint

    async def login(self, client_id: str, client_secret: str) -> None:
        """Exchange client credentials for a DPoP-bound access token."""

        endpoint = await self._token_endpoint()
        # CSS expects each credential URL-encoded before forming Basic auth.
        basic = base64.b64encode(
            f'{quote(client_id)}:{quote(client_secret)}'.encode()).decode()

        async def attempt(nonce: str | None) -> httpx.Response:
            headers = {
                'Authorization': f'Basic {basic}',
                'Content-Type': 'application/x-www-form-urlencoded',
                'DPoP': self.dpop.proof('POST', endpoint, nonce=nonce),
            }
            return await self._http.post(
                endpoint,
                headers=headers,
                content='grant_type=client_credentials&scope=webid',
            )

        resp = await attempt(None)
        # The server may demand a server-chosen nonce; retry once with it.
        if resp.status_code in (400, 401) and 'DPoP-Nonce' in resp.headers:
            resp = await attempt(resp.headers['DPoP-Nonce'])
        if resp.status_code != 200:
            raise RuntimeError(
                f'token HTTP {resp.status_code}: {resp.text[:200]}')
        self.access_token = resp.json()['access_token']

    # -- Authenticated resource access (DPoP) ------------------------------

    async def _authed_request(
        self, method: str, url: str, *,
        content: bytes | None = None,
        content_type: str | None = None) -> httpx.Response:
        """Issue a DPoP-authenticated request, retrying on nonce challenge."""

        if self.access_token is None:
            raise RuntimeError('not logged in')

        async def attempt(nonce: str | None) -> httpx.Response:
            headers = {
                'Authorization': f'DPoP {self.access_token}',
                'DPoP': self.dpop.proof(
                    method, url, nonce=nonce, access_token=self.access_token),
            }
            if content_type is not None:
                headers['Content-Type'] = content_type
            return await self._http.request(
                method, url, headers=headers, content=content)

        resp = await attempt(self._dpop_nonce)
        if resp.status_code == 401 and 'DPoP-Nonce' in resp.headers:
            # Cache the nonce so subsequent requests start with it.
            self._dpop_nonce = resp.headers['DPoP-Nonce']
            resp = await attempt(self._dpop_nonce)
        if 'DPoP-Nonce' in resp.headers:
            self._dpop_nonce = resp.headers['DPoP-Nonce']
        return resp

    async def ensure_container(self, url: str) -> None:
        """Create a container (a URL ending in `/`) if it does not exist.

        The empwr server does not auto-create intermediate containers, so the
        parent container is provisioned explicitly before any resource is
        written into it.
        """

        resp = await self._authed_request(
            'PUT', url,
            content=b'',
            content_type='text/turtle',
        )
        # 201 Created or 205/2xx are fine; CSS returns 4xx if it already exists
        # in some configurations, which is equally acceptable here.
        if not (200 <= resp.status_code < 300 or resp.status_code == 409):
            raise RuntimeError(
                f'create container HTTP {resp.status_code}: {resp.text[:200]}')

    async def put_resource(
        self, url: str, content: bytes, content_type: str) -> None:
        resp = await self._authed_request(
            'PUT', url, content=content, content_type=content_type)
        if not 200 <= resp.status_code < 300:
            raise RuntimeError(
                f'write HTTP {resp.status_code}: {resp.text[:200]}')

    async def get_resource(self, url: str) -> bytes:
        resp = await self._authed_request('GET', url)
        if resp.status_code != 200:
            raise RuntimeError(
                f'read HTTP {resp.status_code}: {resp.text[:200]}')
        return resp.content


# ---------------------------------------------------------------------------
# Per-user lifecycle
# ---------------------------------------------------------------------------


async def run_user(cfg: 'Config', index: int) -> UserResult:
    """Run the full lifecycle for one simulated user.

    Each step is timed independently. A failure aborts the remaining steps for
    this user but never the overall run.

    Each user gets its own [httpx.AsyncClient] (and therefore its own cookie
    jar). This isolation is essential: CSS sets an account session cookie on
    `/.account/` responses, and a shared jar accumulates several of them, which
    makes the server fail concurrent account creation with "Multiple results
    for ... accountCookie". Account auth itself uses the `CSS-Account-Token`
    header, so per-user cookies cost nothing.
    """

    username = f'{cfg.prefix}-{cfg.run_id}-{index:03d}'
    email = f'{username}@{cfg.email_domain}'
    result = UserResult(index=index, email=email)
    started = time.monotonic()

    password = cfg.password
    timeout = httpx.Timeout(60.0, connect=30.0)

    try:
      async with httpx.AsyncClient(
          timeout=timeout, follow_redirects=True) as http:
        client = CssClient(http, cfg.server)
        with _Step(result, 'create_account'):
            token = await client.create_account(email, password)

        with _Step(result, 'create_pod'):
            pod_url = await client.create_pod(token, username)

        web_id = f'{pod_url}profile/card#me'

        if cfg.change_password:
            with _Step(result, 'change_password'):
                new_password = password + '-rotated'
                await client.change_password(token, email, password, new_password)
                password = new_password

        with _Step(result, 'client_credentials'):
            cc_id, cc_secret = await client.issue_client_credentials(
                token, web_id, f'loadtest-{cfg.run_id}')

        with _Step(result, 'login_token'):
            await client.login(cc_id, cc_secret)

        with _Step(result, 'security_key'):
            security_key = SecurityKey.generate()

        # Provision a dedicated container for this run's resources.
        container = f'{pod_url}loadtest/'
        await client.ensure_container(container)

        with _Step(result, 'write'):
            for r in range(cfg.resources):
                name = f'resource-{r:03d}'
                payload = _resource_turtle(name, email)
                if cfg.encrypt:
                    body = security_key.encrypt(payload)
                    await client.put_resource(
                        f'{container}{name}.enc', body,
                        'application/octet-stream')
                else:
                    await client.put_resource(
                        f'{container}{name}.ttl', payload.encode('utf-8'),
                        'text/turtle')
                result.resources_written += 1

        with _Step(result, 'read'):
            for r in range(cfg.resources):
                name = f'resource-{r:03d}'
                if cfg.encrypt:
                    blob = await client.get_resource(f'{container}{name}.enc')
                    restored = security_key.decrypt(blob)
                else:
                    restored = (
                        await client.get_resource(f'{container}{name}.ttl')
                    ).decode('utf-8')
                # Round-trip check: the read content must match what we wrote.
                if email not in restored:
                    raise RuntimeError(
                        f'read-back of {name} did not match written content')
                result.resources_read += 1

        result.ok = True
    except Exception:  # noqa: BLE001 - per-user isolation is intentional.
        # The failing step has already emitted its `phase` event; the user is
        # simply marked as failed and the run continues.
        result.ok = False

    result.total_ms = int((time.monotonic() - started) * 1000)
    _emit(
        'user_done',
        user=index,
        email=email,
        ok=result.ok,
        total_ms=result.total_ms,
        resources_written=result.resources_written,
        resources_read=result.resources_read,
    )
    return result


def _resource_turtle(name: str, email: str) -> str:
    """Build a small turtle document used as the write payload."""

    return (
        '@prefix demo: <#> .\n'
        '@prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .\n'
        '@prefix foaf: <http://xmlns.com/foaf/0.1/> .\n\n'
        f'demo:{name} a demo:LoadTestResource ;\n'
        f'    rdfs:label "Load test resource {name}" ;\n'
        f'    foaf:maker "{email}" ;\n'
        f'    demo:created "{int(time.time())}" .\n'
    )


# ---------------------------------------------------------------------------
# Orchestration
# ---------------------------------------------------------------------------


@dataclass
class Config:
    server: str
    users: int
    concurrency: int
    resources: int
    prefix: str
    email_domain: str
    password: str
    change_password: bool
    encrypt: bool
    run_id: str


async def run(cfg: Config) -> dict[str, Any]:
    """Run every user with bounded concurrency and return the summary dict."""

    _emit(
        'start',
        users=cfg.users,
        concurrency=cfg.concurrency,
        resources=cfg.resources,
        server=cfg.server,
        run_id=cfg.run_id,
        encrypt=cfg.encrypt,
    )

    semaphore = asyncio.Semaphore(cfg.concurrency)
    results: list[UserResult] = []
    completed = 0
    ok_count = 0

    wall_start = time.monotonic()

    # Each user runs under the semaphore with its own HTTP client (created
    # inside run_user) so at most `concurrency` users are in flight at once and
    # no cookie state is shared between them.
    async def guarded(i: int) -> UserResult:
        async with semaphore:
            return await run_user(cfg, i)

    tasks = [asyncio.create_task(guarded(i)) for i in range(cfg.users)]
    for task in asyncio.as_completed(tasks):
        res = await task
        results.append(res)
        completed += 1
        if res.ok:
            ok_count += 1
        _emit(
            'progress',
            completed=completed,
            total=cfg.users,
            ok=ok_count,
            failed=completed - ok_count,
        )

    wall_ms = int((time.monotonic() - wall_start) * 1000)
    summary = _summarise(cfg, results, wall_ms)
    _emit('summary', **summary)
    return summary


def _summarise(
    cfg: Config, results: list[UserResult], wall_ms: int) -> dict[str, Any]:
    """Aggregate per-user timings into mean/p95/max per step plus totals."""

    step_stats: dict[str, dict[str, int]] = {}
    for step in STEP_NAMES:
        durations = [
            ms for r in results
            for (s, (ms, failed)) in r.timings.items()
            if s == step and not failed
        ]
        failures = sum(
            1 for r in results
            for (s, (_ms, failed)) in r.timings.items()
            if s == step and failed
        )
        step_stats[step] = {
            'count': len(durations),
            'failures': failures,
            'mean': int(sum(durations) / len(durations)) if durations else 0,
            'p95': _percentile(durations, 95),
            'max': max(durations) if durations else 0,
        }

    users_ok = sum(1 for r in results if r.ok)
    return {
        'server': cfg.server,
        'run_id': cfg.run_id,
        'users': cfg.users,
        'users_ok': users_ok,
        'users_failed': cfg.users - users_ok,
        'resources_written': sum(r.resources_written for r in results),
        'resources_read': sum(r.resources_read for r in results),
        'wall_ms': wall_ms,
        'steps': step_stats,
    }


def _percentile(values: list[int], pct: int) -> int:
    """Return the [pct]th percentile of [values] (0 if empty)."""

    if not values:
        return 0
    ordered = sorted(values)
    # Nearest-rank method; adequate for load-test reporting.
    rank = max(0, min(len(ordered) - 1,
                      int(round((pct / 100) * len(ordered) + 0.5)) - 1))
    return ordered[rank]


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------


def _parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description='Headless load tester for a Community Solid Server.')
    parser.add_argument(
        '--server', default='https://solid.dev.empwr.au',
        help='Base URL of the Solid server to test.')
    parser.add_argument(
        '--users', type=int, default=10,
        help='Number of simulated users to create.')
    parser.add_argument(
        '--concurrency', type=int, default=10,
        help='Maximum number of users running concurrently.')
    parser.add_argument(
        '--resources', type=int, default=3,
        help='Number of resources each user writes then reads back.')
    parser.add_argument(
        '--prefix', default='loadtest',
        help='Username/email prefix for generated accounts.')
    parser.add_argument(
        '--email-domain', default='example.org',
        help='Email domain for generated accounts.')
    parser.add_argument(
        '--password', default='Load-Test-Pw-1!',
        help='Initial password for every generated account.')
    parser.add_argument(
        '--change-password', action='store_true',
        help='Also exercise the change-password API for each user.')
    parser.add_argument(
        '--no-encrypt', action='store_true',
        help='Write plaintext turtle instead of encrypted resources.')
    parser.add_argument(
        '--run-id', default=None,
        help='Identifier appended to usernames so reruns do not collide '
             '(default: a timestamp).')
    parser.add_argument(
        '--json', action='store_true',
        help='Emit progress as JSON Lines (used by the example app).')
    return parser.parse_args(argv)


def main(argv: list[str]) -> int:
    global _JSON_MODE
    args = _parse_args(argv)
    _JSON_MODE = args.json

    # A timestamp-based run id keeps usernames unique across reruns without
    # needing any persistent state. `time.time()` is used (not a fixed seed) so
    # each invocation is naturally namespaced.
    run_id = args.run_id or str(int(time.time()))

    cfg = Config(
        server=args.server.rstrip('/'),
        users=max(1, args.users),
        concurrency=max(1, args.concurrency),
        resources=max(0, args.resources),
        prefix=args.prefix,
        email_domain=args.email_domain,
        password=args.password,
        change_password=args.change_password,
        encrypt=not args.no_encrypt,
        run_id=run_id,
    )

    try:
        summary = asyncio.run(run(cfg))
    except KeyboardInterrupt:
        _emit('error', message='Interrupted by user')
        return 130
    except Exception as exc:  # noqa: BLE001 - top-level guard for clean output.
        _emit('error', message=str(exc))
        return 1

    # A non-zero exit status when every user failed makes the script usable in
    # CI as well as from the app.
    return 0 if summary['users_ok'] > 0 else 2


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
