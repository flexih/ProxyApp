//
//  AddProxyView.swift
//  ProxyApp
//
//  Created by MSI Shamim on 12/11/24.
//

import SwiftUI

struct AddProxyView: View {
    @ObservedObject var proxyStore: ProxyStore
    @Binding var isPresented: Bool
    
    @State private var proxyAddress = ""
    @State private var proxyPort = ""
    @State private var username = ""
    @State private var password = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Proxy Details")) {
                    TextField("Proxy Address", text: $proxyAddress)
                        .textContentType(.URL)
                        .autocapitalization(.none)
                    
                    TextField("Port", text: $proxyPort)
                        .keyboardType(.numberPad)
                }
                
                Section(header: Text("Authentication (Optional)")) {
                    TextField("Username", text: $username)
                        .textContentType(.username)
                        .autocapitalization(.none)
                    
                    SecureField("Password", text: $password)
                        .textContentType(.password)
                }
            }
            .navigationTitle("Add Proxy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        saveProxy()
                    }
                    .disabled(proxyAddress.isEmpty || proxyPort.isEmpty)
                }
            }
        }
    }
    
    private func saveProxy() {
        let proxy = ProxyModel(
            address: proxyAddress,
            port: proxyPort,
            username: username.isEmpty ? nil : username,
            password: password.isEmpty ? nil : password
        )
        do {
            try proxyStore.add(proxy)
            isPresented = false
        }catch{
            
        }
        
    }
}

#Preview {
    AddProxyView(proxyStore: ProxyStore(), isPresented: .constant(true))
}
