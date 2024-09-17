import SwiftUI

struct SearchResultsView: View {
    let results: [DatabaseSearchResult]
    let originalSearchText: String
    let onSelectResult: (DatabaseSearchResult) -> Void 
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Search Results for \"\(originalSearchText)\"")
                List {
                    ForEach(results.indices, id: \.self) { index in
                        let result = results[index]
                        VStack(alignment: .leading) { 
                            Text("Kural: \(result.kuralId)")
                            Text("Chapter: \(result.subheading)")
                            Text("Line: \(result.content)")
                        }
                        .onTapGesture {
                            onSelectResult(result)
                        }
                    }
                }
            }
            .navigationBarTitle("Search Results : (\(results.count))", displayMode: .inline)
            .navigationBarItems(trailing: Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Image(systemName: "xmark.circle")
                    .foregroundColor(.blue)
                    .font(.system(size: 16))
            })
        } 
    }
}
