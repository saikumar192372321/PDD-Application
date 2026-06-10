// AddressConfigView.swift
// Created to satisfy reference from CartView
import SwiftUI

struct AddressConfigView: View {
    @Binding var shopName: String
    @Binding var shopNumber: String
    @Binding var street: String
    @Binding var landmark: String
    @Binding var city: String
    @Binding var pincode: String
    let onSave: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Shop Details")) {
                    TextField("Shop/Business Name", text: $shopName)
                    TextField("Shop Number", text: $shopNumber)
                }
                Section(header: Text("Address")) {
                    TextField("Street / Area", text: $street)
                    TextField("Landmark (optional)", text: $landmark)
                    TextField("City", text: $city)
                    TextField("Pincode", text: $pincode)
                        .keyboardType(.numberPad)
                }
            }
            .navigationTitle("Shipping Address")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave()
                        dismiss()
                    }
                    .disabled(!isFormValid)
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        // Require minimal fields
        !shopName.isEmpty && !street.isEmpty && !city.isEmpty && pincode.count >= 5
    }
}

#Preview {
    AddressConfigView(
        shopName: .constant("Acme Traders"),
        shopNumber: .constant("12B"),
        street: .constant("Market Road"),
        landmark: .constant("Near Clock Tower"),
        city: .constant("Pune"),
        pincode: .constant("411001"),
        onSave: {}
    )
}
