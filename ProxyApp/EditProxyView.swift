//
//  EditProxyView.swift
//  ProxyApp
//
//  Created by MSI Shamim on 12/11/24.
//


import SwiftUI

struct EditProxyView: View {
    @ObservedObject var proxyStore: ProxyStore
    @Binding var isPresented: Bool
    let proxy: ProxyModel
    
    @State private var proxyAddress: String
    @State private var proxyPort: String
    @State private var username: String
    @State private var password: String
    @State private var isActive: Bool
    
    init(proxyStore: ProxyStore, isPresented: Binding<Bool>, proxy: ProxyModel) {
        self.proxyStore = proxyStore
        self._isPresented = isPresented
        self.proxy = proxy
        
        // Initialize state with proxy values
        _proxyAddress = State(initialValue: proxy.address)
        _proxyPort = State(initialValue: proxy.port)
        _username = State(initialValue: proxy.username ?? "")
        _password = State(initialValue: proxy.password ?? "")
        _isActive = State(initialValue: proxy.isActive)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Proxy Details")) {
                    TextField("Proxy Address", text: $proxyAddress)
                        .textContentType(.URL)
                        .autocapitalization(.none)
                    
                    TextField("Port", text: $proxyPort)
                        .keyboardType(.numberPad)
                    
                    Toggle("Active", isOn: $isActive)
                }
                
                Section(header: Text("Authentication (Optional)")) {
                    TextField("Username", text: $username)
                        .textContentType(.username)
                        .autocapitalization(.none)
                    
                    SecureField("Password", text: $password)
                        .textContentType(.password)
                }
            }
            .navigationTitle("Edit Proxy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        updateProxy()
                    }
                    .disabled(proxyAddress.isEmpty || proxyPort.isEmpty)
                }
            }
        }
    }
    
    private func updateProxy() {
        let updatedProxy = ProxyModel(
            id: proxy.id,
            address: proxyAddress,
            port: proxyPort,
            username: username.isEmpty ? nil : username,
            password: password.isEmpty ? nil : password,
            dateAdded: proxy.dateAdded,
            isActive: isActive
        )
        do{
            try proxyStore.update(updatedProxy)
            isPresented = false
        } catch{
            
        }
        
    }
}
