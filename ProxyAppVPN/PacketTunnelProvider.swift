//
//  PacketTunnelProvider.swift
//  ProxyAppVPN
//
//  Created by MSI Shamim on 12/11/24.
//

import NetworkExtension

class PacketTunnelProvider: NEPacketTunnelProvider {
    
    override func startTunnel(options: [String : NSObject]?, completionHandler: @escaping (Error?) -> Void) {
        // Get the tunnel configuration from options
        guard let tunnelConfig = options?["config"] as? [String: Any],
              let serverAddress = tunnelConfig["serverAddress"] as? String else {
            completionHandler(NSError(domain: "PacketTunnelProvider", code: -1,
                                    userInfo: [NSLocalizedDescriptionKey: "Missing configuration"]))
            return
        }
        
        // Create network settings with the actual server address
        let networkSettings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: serverAddress)
        
        // Configure IPv4 settings for IKEv2
        let ipv4Settings = NEIPv4Settings(addresses: ["192.168.1.1"], subnetMasks: ["255.255.255.0"])
        ipv4Settings.includedRoutes = [NEIPv4Route.default()]
        networkSettings.ipv4Settings = ipv4Settings
        
        // Configure IPv6 settings for IKEv2
        let ipv6Settings = NEIPv6Settings(addresses: ["fd00::1"], networkPrefixLengths: [64])
        ipv6Settings.includedRoutes = [NEIPv6Route.default()]
        networkSettings.ipv6Settings = ipv6Settings
        
        // Configure DNS settings
        networkSettings.dnsSettings = NEDNSSettings(servers: ["8.8.8.8", "8.8.4.4"])
        
        // Configure MTU for IKEv2
        networkSettings.mtu = NSNumber(value: 1380)
        
        // Apply proxy settings if provided
        if let proxyAddress = tunnelConfig["proxyAddress"] as? String,
           let proxyPort = tunnelConfig["proxyPort"] as? Int {
            let proxySettings = NEProxySettings()
            proxySettings.httpEnabled = true
            proxySettings.httpsEnabled = true
            proxySettings.httpServer = NEProxyServer(address: proxyAddress, port: proxyPort)
            proxySettings.httpsServer = NEProxyServer(address: proxyAddress, port: proxyPort)
            networkSettings.proxySettings = proxySettings
        }
        
        // Apply the settings
        setTunnelNetworkSettings(networkSettings) { error in
            if let error = error {
                print("Failed to set tunnel network settings: \(error.localizedDescription)")
                completionHandler(error)
                return
            }
            
            print("IKEv2 Tunnel started successfully")
            completionHandler(nil)
        }
    }
    
    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        // Clean up any IKEv2 specific resources
        print("Stopping IKEv2 tunnel with reason: \(reason)")
        completionHandler()
    }
    
    override func handleAppMessage(_ messageData: Data, completionHandler: ((Data?) -> Void)?) {
        // Handle messages from the containing app
        if let message = String(data: messageData, encoding: .utf8) {
            print("Received message from app: \(message)")
        }
        completionHandler?(nil)
    }
    
    // Handle tunnel connection status changes
    func tunnelConnectionDidChange(with status: NEVPNStatus) {
        switch status {
        case .connected:
            print("Tunnel connected successfully")
        case .connecting:
            print("Tunnel is connecting")
        case .disconnecting:
            print("Tunnel is disconnecting")
        case .disconnected:
            print("Tunnel disconnected")
        case .reasserting:
            print("Tunnel is reasserting")
        case .invalid:
            print("Tunnel status is invalid")
        @unknown default:
            print("Unknown tunnel status")
        }
    }
}
