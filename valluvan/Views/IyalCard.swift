import SwiftUI

    struct IyalCard: View {
        let iyal: String
        let translatedIyal: String
        let selectedLanguage: String
        @Environment(\.colorScheme) var colorScheme
        @EnvironmentObject var appState: AppState

        var body: some View {
            HStack(spacing: 2) {
                Image(systemName: IyalUtils.getSystemImageForIyal(iyal))
                    .foregroundColor(.blue)
                VStack(alignment: .leading, spacing: 4) { 
                    Text(translatedIyal)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                .padding(.vertical, 8) 
                .padding(.horizontal, 2)
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .padding(.trailing, 12) 
            }
            .frame(maxWidth: .infinity)
            .background(backgroundColor)
            .cornerRadius(10)
            .shadow(color: shadowColor, radius: 3, x: 0, y: 2)
            .environment(\.sizeCategory, appState.fontSize.textSizeCategory)
        }
        
        private var backgroundColor: Color {
            colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground)
        }
        
        private var shadowColor: Color {
            colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.1)
        }
    }