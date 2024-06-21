/// Copyright (C) 2024, Software Innovation Institute, ANU.
///
/// Licensed under the MIT License (the "License").
///
/// License: https://choosealicense.com/licenses/mit/.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
///
/// Authors: Anushka Vidanage

/// Represents an ACL resource.
class AclResource {
  /// Constructs a new instance of [AclResource] with the given [aclResStr].
  AclResource(this.aclResStr);

  /// The string representation of the ACL resource.
  String aclResStr = '';

  /// Divides the ACL data into different parts.
  // ignore: strict_raw_type
  List divideAclData() {
    final userNameMap = {};
    final userPermMap = {};

    final prefixRegExp = RegExp(
      '@prefix ([a-zA-Z0-9: <>#].*)',
      caseSensitive: false,
    );

    final accessGroupRegExp = RegExp(
      r'(?<=^:[a-zA-Z]+\n)(?:^\s+.*;$\n)*(?:^\s+.*\.\n?)',
      caseSensitive: false,
      multiLine: true,
    );

    final accessGroupList = accessGroupRegExp.allMatches(aclResStr);
    final prefixList = prefixRegExp.allMatches(aclResStr);

    for (final prefixItem in prefixList) {
      final prefixLine = prefixItem[0].toString();
      if (prefixLine.contains('/card#>')) {
        final itemList = prefixLine.split(' ');
        userNameMap[itemList[1]] =
            itemList[2].substring(0, itemList[2].length - 1);
      }
    }

    for (final accessGroup in accessGroupList) {
      final accessGroupStr = accessGroup[0].toString();

      final accessRegExp = RegExp(
        'acl:access[T|t]o (?<resource><[a-zA-Z0-9_-]*.[a-z]*>)',
        caseSensitive: false,
      );

      final modeRegExp = RegExp(
        'acl:mode ([^.]*)',
        caseSensitive: false,
      );

      final agentRegExp = RegExp(
        'acl:agent[a-zA-Z]*? ([^;]*);',
        caseSensitive: false,
      );

      final accessPers = agentRegExp.allMatches(accessGroupStr);
      final accessRes = accessRegExp.allMatches(accessGroupStr);
      final accessModes = modeRegExp.allMatches(accessGroupStr);

      for (final accessModesItem in accessModes) {
        final accessList = accessModesItem[1].toString().split(',');
        final accessItemList = [];
        final accessItemSet = <dynamic>{};
        for (final accessItem in accessList) {
          accessItemList.add(accessItem.replaceAll('acl:', '').trim());
          accessItemSet.add(accessItem.trim());
        }
        accessItemList.sort();
        final accessStr = accessItemList.join();

        final accessResItemSet = <dynamic>{};
        for (final accessResItem in accessRes) {
          final accessResList = accessResItem[1].toString().split(',');
          for (final accessItem in accessResList) {
            accessResItemSet.add(accessItem.trim());
          }
        }

        final accessPersItemSet = <dynamic>{};
        for (final accessPersItem in accessPers) {
          final accessPersList = accessPersItem[1].toString().split(',');
          for (final accessItem in accessPersList) {
            accessPersItemSet.add(accessItem.replaceAll('me', '').trim());
          }
        }
        userPermMap[accessStr] = [
          accessResItemSet,
          accessPersItemSet,
          accessItemSet
        ];
      }
    }
    return [userNameMap, userPermMap];
  }
}
