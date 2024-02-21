/// POD connection/auth/upload/encrpytion service.
///
/// Copyright (C) 2023, Software Innovation Institute, ANU.
///
/// License: http://www.apache.org/licenses/LICENSE-2.0
///
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
///
/// Authors: Kevin Wang

import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:solid_auth/solid_auth.dart';
import 'package:solid_encrypt/solid_encrypt.dart';

// import 'package:bstim/constants/app.dart';
import 'package:solidpod/src/solid/net.dart';
// import 'package:bstim/pages/settings/net.dart';

class Constants {
  static const issuerUrlBaseEmpwr = 'https://solid.empwr.au';

  static const webIdReplacement = 'profile/card#me';
  static const openid = 'openid';
  static const profile = 'profile';
  static const offlineAccess = 'offline_access';
  static const accessTokenKey = 'accessToken';
  static const webid = 'webid';
  static const rsaInfo = 'rsaInfo';
  static const rsa = 'rsa';
  static const pubKeyJwk = 'pubKeyJwk';
  static const itemLocation = '';
  static const bstimPath = 'bstim';
  static const bstimAppendPath = 'surveys';
  static const settingFileAppendPath = '/symptom_checker_survey';
  static const settingFileAppendPath2 = 'symptom_checker_survey';

  static const PHQ9AppendPath = '/phq_9_survey';
  static const PHQ9AppendPath2 = 'phq_9_survey';

  static const ttl = '.ttl';
  static const connectToPOD = 'Connect to POD';
  static const save1Button = 'Save1Button';
  static const bstimPath2 = 'bstim/';
}

class PodService {
  final FlutterSecureStorage secureStorage;
  final HomePageNet networkService = HomePageNet();

  PodService({
    required this.secureStorage,
  });

  Future<String> getBaseUrl(String url) async {
    Uri uri = Uri.parse(url);

    // Rebuild the URL with only the scheme and the host.

    return Uri(scheme: uri.scheme, host: uri.host).toString();
  }

  Future<Map<dynamic, dynamic>> authenticatePOD(
    String webId,
    BuildContext context,
  ) async {
    String baseUrl = await getBaseUrl(webId);
    String issuerUri = await getIssuer(baseUrl);
    print('issuerUri: $issuerUri');
    final List<String> scopes = [
      Constants.openid,
      Constants.profile,
      Constants.offlineAccess,
    ];
    var authData = await authenticate(
      Uri.parse(issuerUri),
      scopes,
      context,
    );
    print('11authData: $authData');

    return authData;
  }

  Future<void> createFolders(
    String webIdSetting,
    Map<dynamic, dynamic> authData,
    BuildContext context,
  ) async {
    String accessToken = authData[Constants.accessTokenKey];

    Map<String, dynamic> decodedToken = JwtDecoder.decode(accessToken);
    String webId = decodedToken[Constants.webid];
    dynamic rsa = authData[Constants.rsaInfo][Constants.rsa];
    dynamic pubKeyJwk = authData[Constants.rsaInfo][Constants.pubKeyJwk];

    String encDataUrl = webId.replaceAll(
      Constants.webIdReplacement,
      Constants.itemLocation,
    );

    // Create the first folder
    await networkService.mkdir(
      encDataUrl,
      accessToken,
      rsa,
      pubKeyJwk,
      Constants.bstimPath,
    );

    // Wait for 5 seconds.

    await Future.delayed(const Duration(seconds: 5));

    // Update the URL and create the second folder.

    encDataUrl += Constants.bstimPath2;
    await networkService.mkdir(
      encDataUrl,
      accessToken,
      rsa,
      pubKeyJwk,
      Constants.bstimAppendPath,
    );

    // Wait for 5 seconds.

    await Future.delayed(const Duration(seconds: 5));
  }

  Future<void> createSurveyFolders(
    String surveyName,
    String webIdSetting,
    Map<dynamic, dynamic> authData,
    BuildContext context,
  ) async {
    String accessToken = authData[Constants.accessTokenKey];

    Map<String, dynamic> decodedToken = JwtDecoder.decode(accessToken);
    String webId = decodedToken[Constants.webid];
    dynamic rsa = authData[Constants.rsaInfo][Constants.rsa];
    dynamic pubKeyJwk = authData[Constants.rsaInfo][Constants.pubKeyJwk];

    String encDataUrl = webId.replaceAll(
      Constants.webIdReplacement,
      Constants.itemLocation,
    );

    // Create the first folder(bstim)
    await networkService.mkdir(
      encDataUrl,
      accessToken,
      rsa,
      pubKeyJwk,
      Constants.bstimPath,
    );

    // Wait for 0.1 second.

    await Future.delayed(const Duration(milliseconds: 100));

    // Update the URL and create the second folder(surveys).

    encDataUrl += Constants.bstimPath2;
    print('22encDataUrl: $encDataUrl');

    await networkService.mkdir(
      encDataUrl,
      accessToken,
      rsa,
      pubKeyJwk,
      Constants.bstimAppendPath,
    );

    // Wait for 0.1 second.

    await Future.delayed(const Duration(milliseconds: 100));

    // Update the URL and create the third folder(survey_name).

    encDataUrl = "$encDataUrl${Constants.bstimAppendPath}/";

    print('33encDataUrl: $encDataUrl');
    await networkService.mkdir(
      encDataUrl,
      accessToken,
      rsa,
      pubKeyJwk,
      surveyName,
    );

    // // Wait for 1 second.

    // await Future.delayed(Duration(seconds: 1));
  }

  // ignore: long-parameter-list
  Future<void> createAndUploadSurvey(
    String webIdSetting,
    Map<dynamic, dynamic> authData,
    Map<String, String> combinedMap,
    String surveyName,
    BuildContext context,
  ) async {
    String accessToken = authData[Constants.accessTokenKey];
    Map<String, dynamic> decodedToken = JwtDecoder.decode(accessToken);
    String webId = decodedToken[Constants.webid];
    dynamic rsa = authData[Constants.rsaInfo][Constants.rsa];
    dynamic pubKeyJwk = authData[Constants.rsaInfo][Constants.pubKeyJwk];

    String encDataUrl = webId.replaceAll(
          Constants.webIdReplacement,
          Constants.itemLocation,
        ) +
        Constants.bstimPath2;

    String bstimUrl = "$encDataUrl${Constants.bstimAppendPath}/$surveyName";

    // Get the current date and time.

    DateTime now = DateTime.now();
    String formattedDate = DateFormat('yyyyMMdd').format(now);
    String formattedTime = DateFormat('HHmm').format(now);
    String newFilename = '_${formattedDate}_$formattedTime${Constants.ttl}';

    // Create the full URL.

    debugPrint('bstimUrl: $bstimUrl');

    String fileUrl = "$bstimUrl/$surveyName$newFilename";

    debugPrint('fileUrl: $fileUrl');

    // Make a new file in the root directory of a POD.

    await networkService.touch(
      bstimUrl,
      accessToken,
      rsa,
      pubKeyJwk,
      surveyName + newFilename,
    );

    // Convert the map to a ttl string.

    String ttlString = convertMapToTTL(combinedMap, surveyName);

    // Encrypt and upload the data.

    // Set up encryption client object.

    EncryptClient encryptClient = EncryptClient(authData, webId);
    String encryptKey =
        '12345678901234567890123456789012'; // 32-characters string.

    // Encrypt the plaintext file content.

    List encryptValRes = encryptClient.encryptVal(encryptKey, ttlString);
    String encryptValStr = encryptValRes.first;
    String ivValStr = encryptValRes[1];

    String dataToUpload =
        formatEncryptedData(encryptValStr, ivValStr, surveyName);

    debugPrint('dataToUpload: $dataToUpload');

    // Store the encryption key
    // await secureStorage.write(key: 'encKey', value: encryptKey);

    await Future.delayed(const Duration(milliseconds: 100));

    // Write the encrypted data to the file.

    await networkService.updateFile(
      fileUrl,
      accessToken,
      rsa,
      pubKeyJwk,
      dataToUpload,
    );
  }

  Future<void> createAndUploadFile(
    String webIdSetting,
    Map<dynamic, dynamic> authData,
    Map<String, String> combinedMap,
    String surveyName,
    BuildContext context,
  ) async {
    String accessToken = authData[Constants.accessTokenKey];
    Map<String, dynamic> decodedToken = JwtDecoder.decode(accessToken);
    String webId = decodedToken[Constants.webid];
    dynamic rsa = authData[Constants.rsaInfo][Constants.rsa];
    dynamic pubKeyJwk = authData[Constants.rsaInfo][Constants.pubKeyJwk];

    String encDataUrl = webId.replaceAll(
          Constants.webIdReplacement,
          Constants.itemLocation,
        ) +
        Constants.bstimPath2;

    String bstimUrl = encDataUrl + Constants.bstimAppendPath;

    // Get the current date and time.

    DateTime now = DateTime.now();
    String formattedDate = DateFormat('yyyyMMdd').format(now);
    String formattedTime = DateFormat('HHmm').format(now);
    String newFilename = '_${formattedDate}_$formattedTime${Constants.ttl}';

    // Create the full URL.

    debugPrint('bstimUrl: $bstimUrl');

    String fileUrl = bstimUrl + Constants.settingFileAppendPath + newFilename;

    debugPrint('fileUrl: $fileUrl');

    // Make a new file in the root directory of a POD.

    await networkService.touch(
      bstimUrl,
      accessToken,
      rsa,
      pubKeyJwk,
      Constants.settingFileAppendPath2 + newFilename,
    );

    // Convert the map to a ttl string.

    String ttlString = convertMapToTTL(combinedMap, surveyName);

    // Encrypt and upload the data.

    // Set up encryption client object.

    EncryptClient encryptClient = EncryptClient(authData, webId);
    String encryptKey =
        '12345678901234567890123456789012'; // 32-characters string.

    // Encrypt the plaintext file content.

    List encryptValRes = encryptClient.encryptVal(encryptKey, ttlString);
    String encryptValStr = encryptValRes.first;
    String ivValStr = encryptValRes[1];

    String dataToUpload =
        formatEncryptedData(encryptValStr, ivValStr, surveyName);

    debugPrint('dataToUpload: $dataToUpload');

    // Store the encryption key
    // await secureStorage.write(key: 'encKey', value: encryptKey);

    await Future.delayed(const Duration(seconds: 1));

    // Write the encrypted data to the file.

    await networkService.updateFile(
      fileUrl,
      accessToken,
      rsa,
      pubKeyJwk,
      dataToUpload,
    );
  }

  String convertMapToTTL(Map<String, dynamic> data, String surveyName) {
    // Define prefixes.
    var ttlString = '''@prefix foaf: <http://xmlns.com/foaf/0.1/> .
@prefix schema: <http://schema.org/> .
@prefix empwr: <http://empwr.au/predicates/oci_r#> .
@prefix session: <http://example.org/session/> .
@prefix xsd: <http://www.w3.org/2001/XMLSchema#> .
@prefix : <https://solid.empwr.au/u7274552/bstim/surveys/$surveyName/> .

: a foaf:PersonalProfileDocument ;
  foaf:maker :me ;
  foaf:primaryTopic :me .

:$surveyName a $surveyName:$surveyName ;\n''';

    // Iterate over the map and append key-value pairs to the ttl string.
    data.forEach((key, value) {
      // Append the session prefix to the key.
      String predicate = convertKeyToPredicate(key);
      // Determine the type of the value.
      String object = value is String ? '"$value"' : '"$value"^^xsd:integer';
      // Append the predicate-object pair to the ttl string.
      ttlString += '  $predicate $object ;\n';
    });

    // Replace the last semicolon with a period to end the statements.
    ttlString = ttlString.trim();
    if (ttlString.endsWith(';')) {
      ttlString = '${ttlString.substring(0, ttlString.length - 1)} .';
    }

    return ttlString;
  }

  String convertKeyToPredicate(String key) {
    // Replace spaces and other undesired characters in the key.
    // Here we replace spaces with an underscore, but you can choose another method like camelCase.

    return 'question:${key.replaceAll(' ', '_')}';
  }

  String formatEncryptedData(
    String encryptValStr,
    String ivValStr,
    String surveyName,
  ) {
    return '''
https://solid.empwr.au/u7274552/bstim/surveys/$surveyName/ a http://xmlns.com/foaf/0.1/PersonalProfileDocument;
http://xmlns.com/foaf/0.1/maker <#me>;
http://xmlns.com/foaf/0.1/primaryTopic <#me>.
<#me> a http://schema.org/Person, http://xmlns.com/foaf/0.1/Person;
http://empwr.au/predicates/$surveyName#ivz "$ivValStr";
http://empwr.au/predicates/$surveyName#encryptVal "$encryptValStr".
  '''
        .trim();
  }
}
