//
//  KeychainHelper.swift
//  MailMind
//
//  Created by Ritthick Thiaga on 11/3/2026.
//

import Foundation
import Security

enum KeychainHelper {
      static func save(key: String, value: String) {
          let data = value.data(using: .utf8)!
          let query: [CFString: Any] = [
              kSecClass: kSecClassGenericPassword,
              kSecAttrAccount: key,
              kSecValueData: data
          ]
          SecItemDelete(query as CFDictionary)
          SecItemAdd(query as CFDictionary, nil)
      }

      static func load(key: String) -> String? {
          let query: [CFString: Any] = [
              kSecClass: kSecClassGenericPassword,
              kSecAttrAccount: key,
              kSecReturnData: true,
              kSecMatchLimit: kSecMatchLimitOne
          ]
          var result: AnyObject?
          SecItemCopyMatching(query as CFDictionary, &result)
          guard let data = result as? Data else { return nil }
          return String(data: data, encoding: .utf8)
      }

      static func delete(key: String) {
          let query: [CFString: Any] = [
              kSecClass: kSecClassGenericPassword,
              kSecAttrAccount: key
          ]
          SecItemDelete(query as CFDictionary)
      }
  }
