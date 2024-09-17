import SwiftUI

struct SearchBarView: View {
    @Binding var searchText: String
    @Binding var isSearching: Bool
    @Binding var searchResults: [DatabaseSearchResult]
    @Binding var isShowingSearchResults: Bool
    var performSearch: () -> Void

    var body: some View {
        VStack {
            HStack {
                TextField("AI Search", text: $searchText, onCommit: performSearch)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                        isShowingSearchResults = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                    }
                    .padding(.trailing)
                }
            }
            
            if isSearching {
                ProgressView()
            }
        }
    }
}
