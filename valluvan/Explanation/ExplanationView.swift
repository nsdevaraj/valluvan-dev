//
//  ExplanationView 2.swift
//  Valluvan
//
//  Created by Devaraj NS on 04/10/24.
//


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
        _viewModel = StateObject(wrappedValue: ExplanationViewModel(kuralId: kuralId, adhigaram: adhigaram, adhigaramId: adhigaramId, lines: lines, explanation: explanation.string, iyal: iyal))
    }

    var body: some View {
            NavigationView {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        HeaderView(adhigaramId: adhigaramId, adhigaram: adhigaram, kuralId: kuralId, iyal: iyal)
                        LinesView(lines: lines)
                        ExplanationTextView(selectedLanguage: selectedLanguage, explanation: explanation) 
                       
                            if viewModel.isLoading {
                                ProgressView()
                            } else { 
                                DisclosureGroup("Related :") {
                                    ForEach(viewModel.relatedKurals) { kural in
                                        VStack(alignment: .leading) {
                                            Text(kural.heading)
                                                .font(.headline)
                                            Text(kural.content)
                                                .font(.subheadline)
                                            Text(kural.explanation)
                                                .font(.body)
                                                .padding(.bottom, 10)
                                        }
                                        .padding()
                                    }
                                }
                                .padding()
                            }
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
                        kuralId: kuralId,
                        toggleFavorite: viewModel.toggleFavorite,
                        copyContent: viewModel.copyContent,
                        toggleSpeech: viewModel.toggleSpeech,
                        tamilSpeech: viewModel.tamilSpeech,
                        dismiss: { presentationMode.wrappedValue.dismiss() }
                    )
                )
            }
            .onAppear {
                viewModel.checkIfFavorite()
                viewModel.fetchRelatedKurals()
            }
            .onDisappear {
                viewModel.stopSpeech()
            }
            .sheet(isPresented: $viewModel.showShareSheet) {
                ShareSheet(activityItems: [viewModel.getShareContent()])
            }
            .environment(\.sizeCategory, appState.fontSize.textSizeCategory)
            .environment(\.layoutDirection, selectedLanguage == "arabic" ? .rightToLeft : .leftToRight) 
    }
}
