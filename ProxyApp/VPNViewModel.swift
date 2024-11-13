//
//  VPNViewModel.swift
//  ProxyApp
//
//  Created by MSI Shamim on 12/11/24.
//


import Foundation
import NetworkExtension

@MainActor
class VPNViewModel: ObservableObject {
    @Published private(set) var isConfiguring = false
    @Published private(set) var vpnStatus: NEVPNStatus = .invalid
    @Published var errorMessage: String?
    
    private let vpnManager = VPNManager.shared
    
    init() {
        // Observe VPN status changes
        vpnStatus = vpnManager.status
        
        Task {
            for await status in NotificationCenter.default.notifications(
                named: NSNotification.Name.NEVPNStatusDidChange
            ).compactMap({ ($0.object as? NEVPNConnection)?.status }) {
                self.vpnStatus = status
            }
        }
    }
    
    func configureAndConnect(proxy: ProxyModel) async {
        isConfiguring = true
        defer { isConfiguring = false }
        
        do {
            // Configure VPN with proxy settings
            try await vpnManager.configureVPN(with: proxy)
            
            // Connect to VPN
            try await vpnManager.connect()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func disconnect() async {
        do {
            try await vpnManager.disconnect()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}