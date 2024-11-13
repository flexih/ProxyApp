//
//  ProxyStore.swift
//  ProxyApp
//
//  Created by MSI Shamim on 12/11/24.
//

import Foundation

@MainActor
class ProxyStore: ObservableObject {
    @Published private(set) var proxies: [ProxyModel] = []
    private let saveKey = "SavedProxies"
    
    init() {
        loadProxies()
    }
    
    // MARK: - Public Methods
    
    func add(_ proxy: ProxyModel) throws {
        // Parse and validate the proxy format
        let components = proxy.address.split(separator: ":")
        if components.isEmpty {
            throw ProxyError.invalidFormat("Invalid proxy address format")
        }
        
        // Create a new proxy with parsed components
        var newProxy = proxy
        if components.count >= 2 {
            newProxy = ProxyModel(
                id: proxy.id,
                address: String(components[0]),
                port: String(components[1]),
                username: components.count > 2 ? String(components[2]) : proxy.username,
                password: components.count > 3 ? String(components[3]) : proxy.password,
                dateAdded: proxy.dateAdded,
                isActive: proxy.isActive
            )
        }
        
        proxies.append(newProxy)
        saveProxies()
    }
    
    func update(_ proxy: ProxyModel) throws {
        if let index = proxies.firstIndex(where: { $0.id == proxy.id }) {
            // Parse and validate the proxy format
            let components = proxy.address.split(separator: ":")
            if components.isEmpty {
                throw ProxyError.invalidFormat("Invalid proxy address format")
            }
            
            // Create updated proxy with parsed components
            var updatedProxy = proxy
            if components.count >= 2 {
                updatedProxy = ProxyModel(
                    id: proxy.id,
                    address: String(components[0]),
                    port: String(components[1]),
                    username: components.count > 2 ? String(components[2]) : proxy.username,
                    password: components.count > 3 ? String(components[3]) : proxy.password,
                    dateAdded: proxy.dateAdded,
                    isActive: proxy.isActive
                )
            }
            
            proxies[index] = updatedProxy
            saveProxies()
        }
    }
    
    func toggleActive(_ proxy: ProxyModel) {
        if let index = proxies.firstIndex(where: { $0.id == proxy.id }) {
            var updatedProxy = proxy
            updatedProxy.isActive.toggle()
            proxies[index] = updatedProxy
            
            // Deactivate other proxies if this one is being activated
            if updatedProxy.isActive {
                for i in proxies.indices where i != index {
                    proxies[i].isActive = false
                }
            }
            
            saveProxies()
        }
    }
    
    func remove(_ proxy: ProxyModel) {
        proxies.removeAll { $0.id == proxy.id }
        saveProxies()
    }
    
    func remove(at offsets: IndexSet) {
        proxies.remove(atOffsets: offsets)
        saveProxies()
    }
    
    // MARK: - Private Methods
    
    private func loadProxies() {
        guard let data = UserDefaults.standard.data(forKey: saveKey) else { return }
        
        do {
            proxies = try JSONDecoder().decode([ProxyModel].self, from: data)
        } catch {
            print("Error loading proxies: \(error)")
        }
    }
    
    private func saveProxies() {
        do {
            let data = try JSONEncoder().encode(proxies)
            UserDefaults.standard.set(data, forKey: saveKey)
        } catch {
            print("Error saving proxies: \(error)")
        }
    }
}

// MARK: - Error Types
enum ProxyError: LocalizedError {
    case invalidFormat(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidFormat(let message):
            return message
        }
    }
}
