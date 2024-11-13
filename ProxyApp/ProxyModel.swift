//
//  ProxyModel.swift
//  ProxyApp
//
//  Created by MSI Shamim on 12/11/24.
//

import Foundation

struct ProxyModel: Identifiable, Codable, Equatable {
    var id: UUID
        var address: String
        var port: String
        var username: String?
        var password: String?
        var dateAdded: Date
        var isActive: Bool
        
        init(id: UUID = UUID(),
             address: String,
             port: String,
             username: String? = nil,
             password: String? = nil,
             dateAdded: Date = Date(),
             isActive: Bool = false) {
            self.id = id
            self.address = address
            self.port = port
            self.username = username
            self.password = password
            self.dateAdded = dateAdded
            self.isActive = isActive
        }
    
    var displayString: String {
            if let username = username, !username.isEmpty {
                return "\(username)@\(address):\(port)"
            }
            return "\(address):\(port)"
        }
    
    // Helper method to get combined connection string
    var connectionString: String {
            if let username = username, !username.isEmpty,
               let password = password, !password.isEmpty {
                return "\(address):\(port):\(username):\(password)"
            }
            return "\(address):\(port)"
        }
}

// MARK: - Validation Extension
extension ProxyModel {
    var isValidFormat: Bool {
        guard !address.isEmpty && !port.isEmpty else { return false }
        
        // Validate port number
        if let portNum = Int(port) {
            return portNum > 0 && portNum <= 65535
        }
        return false
    }
}
