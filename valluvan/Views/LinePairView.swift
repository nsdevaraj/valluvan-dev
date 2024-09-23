import SwiftUI

struct LinePairView: View {
    let linePair: [String]
    let language: String
    let onTap: ([String], Int) -> Void
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var appState: AppState

    var body: some View {
        let parts = linePair[0].split(separator: " ", maxSplits: 1, omittingEmptySubsequences: true)
        let kuralId = Int(parts[0]) ?? 0
        let firstLine = String(parts[1])
        let secondLine = linePair.count > 1 ? linePair[1] : ""
        
        return ZStack(alignment: language == "arabic" ? .topLeading : .topTrailing) {

            Text("\(kuralId)")
                .font(.system(size: 12))
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
                .background(Color.teal.opacity(0.8))
                .clipShape(Circle())
                .padding([.top, .trailing], 4)
            .padding(.vertical, 8)
            .padding(.horizontal, 12)

            HStack(alignment: .top, spacing: 15) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(firstLine)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    if !secondLine.isEmpty {
                        Text(secondLine)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                }
                Spacer()
            }
            .environment(\.layoutDirection, language == "arabic" ? .rightToLeft : .leftToRight)
            
        }
        .frame(maxWidth: .infinity)
        .background(colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground))
        .cornerRadius(10)
        .shadow(color: shadowColor, radius: 5, x: 0, y: 2)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap([firstLine, secondLine], kuralId)
        }
        .environment(\.sizeCategory, appState.fontSize.textSizeCategory)
    }
    
    private var shadowColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.1)
    }
}
