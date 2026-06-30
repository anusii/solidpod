# Solid load tester

A headless stress tester for a Community Solid Server (CSS v7+), used to verify
that Pod hosting, login and read/write access hold up at scale (up to ~100
concurrent users).

For each simulated user it runs the full lifecycle against the target server:

1. **Create an account** — CSS account JSON API (`/.account/`).
2. **Create a Pod**.
3. **Change password** *(optional)* — exercises the change-password API.
4. **Issue client credentials**.
5. **Log in** — OAuth `client_credentials` grant with a DPoP-bound token.
6. **Create a security key** — a per-user passphrase from which an AES-256 key
   is derived.
7. **Write resources** — authenticated `PUT`, encrypted by default.
8. **Read resources back** — authenticated `GET`, decrypted and verified.

The account-management flow mirrors solidpod's `css_account_api.dart`. The
read/write flow uses CSS client credentials + DPoP because solidpod/solidui only
support interactive (browser) OIDC login, which does not scale to a hundred
automated users.

> The "security key" here plays the same role as solidpod's master key, but the
> on-Pod encryption format is intentionally simpler than solidpod's. Encrypted
> resources written by this tester are not meant to be read back by the app.

## Running it

The example app can launch this script for you (see the **Load Testing** section
on the demonstrator's home screen). To run it standalone:

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

python3 solid_load_test.py \
    --server https://solid.dev.empwr.au \
    --users 100 \
    --concurrency 20 \
    --resources 3
```

### Useful options

| Option               | Default                    | Meaning                                   |
| -------------------- | -------------------------- | ----------------------------------------- |
| `--server`           | `https://solid.dev.empwr.au` | Server under test.                      |
| `--users`            | `10`                       | Number of accounts/Pods to create.        |
| `--concurrency`      | `10`                       | Maximum users running at once.            |
| `--resources`        | `3`                        | Resources each user writes then reads.    |
| `--prefix`           | `loadtest`                 | Username/email prefix.                     |
| `--email-domain`     | `example.org`              | Email domain for generated accounts.      |
| `--password`         | `Load-Test-Pw-1!`          | Initial account password.                 |
| `--change-password`  | off                        | Also exercise the change-password API.    |
| `--no-encrypt`       | off                        | Write plaintext turtle instead of sealed. |
| `--run-id`           | timestamp                  | Namespaces usernames so reruns differ.    |
| `--json`             | off                        | Emit JSON Lines (used by the app).        |

Each run namespaces its accounts as `<prefix>-<run-id>-<NNN>`, so repeated runs
do not collide. The accounts and Pods are left in place on the server.

## Output

Without `--json`, progress and a final summary are printed as readable text.
With `--json`, every update is a single line of JSON (JSON Lines) — `start`,
`phase`, `user_done`, `progress` and a final `summary` event — which the example
app parses to render live progress.
