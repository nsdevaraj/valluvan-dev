import SwiftUI

struct GoToKuralView: View {
    @EnvironmentObject var appState: AppState
    @Binding var isPresented: Bool
    @Binding var kuralId: String
    var onSubmit: () -> Void
    @FocusState private var isTextFieldFocused: Bool
    @State private var showInvalidKuralAlert = false

    var body: some View {
        NavigationView {
            VStack {
                TextField("Enter Kural ID (1-1330)", text: $kuralId, onCommit: {
                    validateAndSubmit()
                })
                .keyboardType(.numberPad)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                .focused($isTextFieldFocused)
                Button(action: {
                    validateAndSubmit()
                }) {
                HStack {
                    Image(systemName: "arrow.right.circle.fill")
                        .foregroundColor(.white)
                    Text("Go to Kural")
                        .foregroundColor(.white)
                        .bold()
                }
                .padding()
                .background(Color.blue)
                .cornerRadius(10)
                }
                .padding()
            }
            .navigationBarTitle("Go to Kural", displayMode: .inline)
            .navigationBarItems(trailing: Button(action: {
                isPresented = false
            }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.blue)
            })
            .alert(isPresented: $showInvalidKuralAlert) {
                Alert(
                    title: Text("Invalid Kural ID"),
                    message: Text("Please enter a valid Kural ID between 1 and 1330."),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
        .environment(\.sizeCategory, appState.fontSize.textSizeCategory)
        .onAppear {
            isTextFieldFocused = true
        }
    }

    private func validateAndSubmit() {
        guard let id = Int(kuralId), (1...1330).contains(id) else {
            showInvalidKuralAlert = true
            return
        }
        onSubmit()
    }
}