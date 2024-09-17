import SwiftUI
import AVFoundation

struct ExplanationView: View {
    let adhigaram: String
    let adhigaramId: String
    let lines: [String]
    let explanation: NSAttributedString
    let selectedLanguage: String
    let kuralId: Int
    let iyal: String
    @Binding var shouldNavigateToContentView: Bool
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel: ExplanationViewModel
    @EnvironmentObject var appState: AppState

    init(adhigaram: String, adhigaramId: String, lines: [String], explanation: NSAttributedString, selectedLanguage: String, kuralId: Int, iyal: String, shouldNavigateToContentView: Binding<Bool>) {
        self.adhigaram = adhigaram
        self.adhigaramId = adhigaramId
        self.lines = lines
        self.explanation = explanation
        self.selectedLanguage = selectedLanguage
        self.kuralId = kuralId
        self.iyal = iyal
        self._shouldNavigateToContentView = shouldNavigateToContentView
        _viewModel = StateObject(wrappedValue: ExplanationViewModel(kuralId: kuralId, adhigaram: adhigaram, adhigaramId: adhigaramId, lines: lines, explanation: explanation.string))
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HeaderView(adhigaramId: adhigaramId, adhigaram: adhigaram, kuralId: kuralId, iyal: iyal)
                    LinesView(lines: lines)
                    ExplanationTextView(selectedLanguage: selectedLanguage, explanation: explanation)
                }
                .padding()
            }
            .navigationBarItems(
                leading: HStack{
                    Button(action: {
                        shouldNavigateToContentView = true
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack {
                            Image(systemName: "house")
                        }
                    }
                },
                trailing: ToolbarView(
                isFavorite: $viewModel.isFavorite,
                isSpeaking: $viewModel.isSpeaking,
                showShareSheet: $viewModel.showShareSheet,
                selectedLanguage: selectedLanguage,
                toggleFavorite: viewModel.toggleFavorite,
                copyContent: viewModel.copyContent,
                toggleSpeech: viewModel.toggleSpeech,
                dismiss: { presentationMode.wrappedValue.dismiss() }
            ))
        }
        .onAppear {
            viewModel.checkIfFavorite()
        }
        .onDisappear {
            viewModel.stopSpeech()
        }
        .sheet(isPresented: $viewModel.showShareSheet) {
            ShareSheet(activityItems: [viewModel.getShareContent()])
        }
        .environment(\.sizeCategory, appState.fontSize.textSizeCategory)
    }
}
