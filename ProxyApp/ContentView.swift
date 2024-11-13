//
//  ContentView.swift
//  ProxyApp
//
//  Created by MSI Shamim on 12/11/24.
//

import SwiftUI
import NetworkExtension

struct ContentView: View {
    @StateObject private var proxyStore = ProxyStore()
    @State private var showingAddProxy = false
    @State private var selectedProxy: ProxyModel?
    
    var body: some View {
        NavigationStack {
            VStack {
                // Header Card
                VStack {
                    Image(systemName: "globe")
                        .imageScale(.large)
                        .font(.system(size: 60))
                        .foregroundStyle(.tint)
                        .padding(.bottom, 10)
                    
                    Text("Secure & Anonymous")
                        .font(.largeTitle)
                    
                    Text("Add new proxy to make your browsing anonymous and robust.")
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.1)))
                .padding()
                
                // Proxy List
                List {
                    ForEach(proxyStore.proxies) { proxy in
                        ProxyRow(proxy: proxy, proxyStore: proxyStore)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedProxy = proxy
                            }
                    }
                    .onDelete(perform: proxyStore.remove)
                }
            }
            .navigationTitle("ProxyApp")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showingAddProxy.toggle() }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showingAddProxy) {
                AddProxyView(proxyStore: proxyStore, isPresented: $showingAddProxy)
            }
            .sheet(item: $selectedProxy) { proxy in
                EditProxyView(proxyStore: proxyStore, isPresented: .constant(true), proxy: proxy)
            }
        }
    }
}

struct ProxyRow: View {
    let proxy: ProxyModel
    @ObservedObject var proxyStore: ProxyStore
    @StateObject private var vpnViewModel = VPNViewModel()
    
    var body: some View {
        HStack {
            // Left side - Proxy Information
            VStack(alignment: .leading, spacing: 4) {
                // Proxy Address
                Text(proxy.displayString)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.primary)
                
                // Status Indicators
                HStack(spacing: 8) {
                    // Authentication Status
                    if proxy.username != nil {
                        Label("Authenticated", systemImage: "lock.fill")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    // Connection Status
                    if proxy.isActive {
                        Label("Active", systemImage: "circle.fill")
                            .font(.caption2)
                            .foregroundColor(.green)
                    }
                }
                
                // Date Added
                Text("Added: \(proxy.dateAdded.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Right side - Connection Toggle
            VStack {
                Toggle("", isOn: Binding(
                    get: { proxy.isActive },
                    set: { newValue in
                        if newValue {
                            Task {
                                await vpnViewModel.configureAndConnect(proxy: proxy)
                            }
                        } else {
                            Task {
                                await vpnViewModel.disconnect()
                            }
                        }
                        proxyStore.toggleActive(proxy)
                    }
                ))
                .labelsHidden()
                
                // VPN Status (if active)
                if proxy.isActive {
                    Text(vpnViewModel.vpnStatus.description)
                        .font(.caption2)
                        .foregroundColor(statusColor(for: vpnViewModel.vpnStatus))
                }
            }
        }
        .padding(.vertical, 4)
        .alert("VPN Error", isPresented: Binding(
            get: { vpnViewModel.errorMessage != nil },
            set: { if !$0 { vpnViewModel.errorMessage = nil } }
        )) {
            Button("OK") { vpnViewModel.errorMessage = nil }
        } message: {
            if let error = vpnViewModel.errorMessage {
                Text(error)
            }
        }
    }
    
    // Helper function for status colors
    private func statusColor(for status: NEVPNStatus) -> Color {
        switch status {
        case .connected:
            return .green
        case .connecting, .reasserting:
            return .orange
        case .disconnected, .invalid, .disconnecting:
            return .red
        @unknown default:
            return .gray
        }
    }
}

// Preview provider
#Preview {
    ContentView()
}
