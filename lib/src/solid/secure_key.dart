/// Represents a Secure Key object.
class SecureKey {
  /// Encryption key
  late String secureKeyStr;

  /// webId of the user
  late String webId;

  /// Constructs a new instance of [SecureKey] with the given [secureKeyStr] and [webId].
  SecureKey(String secureKeyStr, String webId) {
    this.secureKeyStr = secureKeyStr;
    this.webId = webId;
  }

  /// Return secure key
  String getSecureKey() {
    return secureKeyStr;
  }

  /// Return web id
  String getWebId() {
    return webId;
  }

  /// Update secure key
  void updateSecureKey(String newSecureKey) {
    secureKeyStr = newSecureKey;
  }

  /// Update web id
  void updateWebId(String newWebId) {
    webId = newWebId;
  }
}
