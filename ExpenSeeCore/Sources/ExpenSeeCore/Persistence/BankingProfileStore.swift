//
//  BankingProfileStore.swift
//  ExpenSee
//
//  Created by Harvy Angelo Tan on 8/15/26.
//

import Foundation
import Security
import LocalAuthentication

public struct BankingDetails: Codable, Sendable {
    public var accountHolderName: String
    public var maskedAccountNumber: String
    public var routingNumber: String
    
    public init(accountHolderName: String, maskedAccountNumber: String, routingNumber: String) {
        self.accountHolderName = accountHolderName
        self.maskedAccountNumber = maskedAccountNumber
        self.routingNumber = routingNumber
    }
}

public final class BankingProfileStore: Sendable {
    private let service = "harvy-angelo-tan.ExpenSee.banking"
    private let account = "primaryBankingDetails"
    private let accessGroup = "group.harvy-angelo-tan.ExpenSee"
    
    public init() {}
    
    public func saveDetails(_ details: BankingDetails) throws {
        let data = try JSONEncoder().encode(details)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecAttrAccessGroup as String: accessGroup,
            kSecValueData as String: data
        ]
        
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            throw KeychainError.unhandledError(status: status)
        }
    }
    
    public func fetchDetailsWithBiometrics(reason: String = "Authenticate to view banking details") async throws -> BankingDetails {
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            throw KeychainError.biometricsUnavailable
        }
        
        let authenticated = try await context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason)
        guard authenticated else { throw KeychainError.authenticationFailed }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecAttrAccessGroup as String: accessGroup,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        guard status == errSecSuccess, let data = dataTypeRef as? Data else {
            throw KeychainError.itemNotFound
        }
        
        return try JSONDecoder().decode(BankingDetails.self, from: data)
    }
    
    public enum KeychainError: Error {
        case biometricsUnavailable
        case authenticationFailed
        case unhandledError(status: OSStatus)
        case itemNotFound
    }
}
