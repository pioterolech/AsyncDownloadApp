import SwiftUI

struct AddLinkView: View {
    @Bindable var viewModel: AddLinkViewModel
    let onDismiss: () -> Void

    @FocusState private var isFieldFocused: Bool

    var body: some View {
        Form {
            Section {
                TextField("https://example.com/file.zip", text: $viewModel.urlText)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .focused($isFieldFocused)

                if let error = viewModel.validationError {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            } header: {
                Text("URL")
            }
        }
        .navigationTitle("Add Download")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") { onDismiss() }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Add") {
                    Task {
                        let success = await viewModel.add()
                        if success { onDismiss() }
                    }
                }
                .disabled(viewModel.urlText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .onAppear { isFieldFocused = true }
    }
}
