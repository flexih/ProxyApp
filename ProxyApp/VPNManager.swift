//
//  VPNManager.swift
//  ProxyApp
//
//  Created by MSI Shamim on 12/11/24.
//

import Foundation
import NetworkExtension

@MainActor
class VPNManager: ObservableObject {
    @Published private(set) var status: NEVPNStatus = .invalid
    @Published private(set) var isConnecting = false
    @Published var lastError: String?
    
    static let shared = VPNManager()
    private let vpnManager = NEVPNManager.shared()
    
    private init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(vpnStatusDidChange(_:)),
            name: NSNotification.Name.NEVPNStatusDidChange,
            object: nil
        )
        
        Task {
            await loadConfiguration()
        }
    }
    
    // MARK: - Public Methods
    
    func configureVPN(with proxy: ProxyModel) async throws {
        isConnecting = true
        defer { isConnecting = false }
        
        // Instead of parsing address, use connectionString
        let fullString = proxy.connectionString
        let components = fullString.split(separator: ":")
        
        guard components.count >= 4 else {
            throw NSError(domain: "VPNManager", code: -1,
                         userInfo: [NSLocalizedDescriptionKey: "Invalid proxy format"])
        }
        
        let host = String(components[0])
        let port = String(components[1])
        let username = String(components[2])
        let password = String(components[3])
        
        // Load current preferences
        try await vpnManager.loadFromPreferences()
        
        // Create protocol configuration
        let vpnProtocol = NEVPNProtocolIKEv2()
        
        // Configure server settings
        vpnProtocol.serverAddress = host
        
        // Configure authentication
        vpnProtocol.username = username
        vpnProtocol.localIdentifier = username
        vpnProtocol.passwordReference = try storePassword(password)
        
        // Basic VPN settings
        vpnProtocol.authenticationMethod = .none
        vpnProtocol.useExtendedAuthentication = true
        
        // Configure Child Security Association Parameters
        vpnProtocol.childSecurityAssociationParameters.encryptionAlgorithm = .algorithmAES256
        vpnProtocol.childSecurityAssociationParameters.diffieHellmanGroup = .group14
        vpnProtocol.childSecurityAssociationParameters.integrityAlgorithm = .SHA256
        vpnProtocol.childSecurityAssociationParameters.lifetimeMinutes = 1440 // 24 hours
        
        // Configure IKE Security Association Parameters
        vpnProtocol.ikeSecurityAssociationParameters.encryptionAlgorithm = .algorithmAES256
        vpnProtocol.ikeSecurityAssociationParameters.diffieHellmanGroup = .group14
        vpnProtocol.ikeSecurityAssociationParameters.integrityAlgorithm = .SHA256
        vpnProtocol.ikeSecurityAssociationParameters.lifetimeMinutes = 1440 // 24 hours
        
        // Configure proxy settings
        let proxySettings = NEProxySettings()
        proxySettings.httpEnabled = true
        proxySettings.httpsEnabled = true
        proxySettings.httpServer = NEProxyServer(address: host, port: Int(port) ?? 0)
        proxySettings.httpsServer = NEProxyServer(address: host, port: Int(port) ?? 0)
        
        vpnProtocol.proxySettings = proxySettings
        
        // Configure the VPN
        vpnManager.protocolConfiguration = vpnProtocol
        vpnManager.localizedDescription = "ProxyApp VPN"
        vpnManager.isEnabled = true
        
        // Save to preferences
        try await vpnManager.saveToPreferences()
        
        // Reload configuration
        await loadConfiguration()
    }
    
    func connect() async throws {
        guard status != .connected else { return }
        
        try await requestVPNPermissions()
        
        guard let serverAddress = vpnManager.protocolConfiguration?.serverAddress,
              let proxyServer = vpnManager.protocolConfiguration?.proxySettings?.httpServer else {
            throw NSError(domain: "VPNManager", code: -1,
                         userInfo: [NSLocalizedDescriptionKey: "Missing configuration"])
        }
        
        let tunnelConfig: [String: Any] = [
            "serverAddress": serverAddress,
            "proxyAddress": proxyServer.address,
            "proxyPort": proxyServer.port
        ]
        
        isConnecting = true
        try await vpnManager.loadFromPreferences()
        try vpnManager.connection.startVPNTunnel(options: ["config": tunnelConfig as NSObject])
    }
    
    func disconnect() async throws {
        guard status != .disconnected else { return }
        vpnManager.connection.stopVPNTunnel()
    }
    
    // MARK: - Private Methods
    
    private func requestVPNPermissions() async throws {
        return try await withCheckedThrowingContinuation { continuation in
            NEVPNManager.shared().loadFromPreferences { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
    
    private func loadConfiguration() async {
        do {
            try await vpnManager.loadFromPreferences()
            status = vpnManager.connection.status
        } catch {
            lastError = error.localizedDescription
        }
    }
    
    private func storePassword(_ password: String) throws -> Data {
        let account = vpnManager.protocolConfiguration?.serverAddress ?? UUID().uuidString
        return try KeychainManager.shared.storePassword(password, for: account)
    }
    
    @objc private func vpnStatusDidChange(_ notification: Notification) {
        guard let connection = notification.object as? NEVPNConnection else { return }
        
        Task { @MainActor in
            self.status = connection.status
            self.isConnecting = connection.status == .connecting
            
            if connection.status == .invalid {
                self.lastError = "VPN configuration is invalid"
            }
        }
    }
}

// MARK: - Helper Extensions

extension NEVPNStatus: @retroactive CustomStringConvertible {
    public var description: String {
        switch self {
        case .invalid:
            return "Invalid"
        case .disconnected:
            return "Disconnected"
        case .connecting:
            return "Connecting"
        case .connected:
            return "Connected"
        case .reasserting:
            return "Reconnecting"
        case .disconnecting:
            return "Disconnecting"
        @unknown default:
            return "Unknown"
        }
    }
}
