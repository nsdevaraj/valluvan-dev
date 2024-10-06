import SwiftUI

struct SearchBarView: View {
    @Binding var searchText: String
    @Binding var isSearching: Bool
    @Binding var searchResults: [DatabaseSearchResult]
    @Binding var isShowingSearchResults: Bool
    var performSearch: () -> Void
    @Binding var selectedLanguage: String
    @Binding var originalSearchText: String
    
    @State private var expandedCategory: String?
    @State private var showSuggestedSearches: Bool = false

    let defaultSearchOptions: [String: [(String, [Int])]] = [
        "Love and Relationships": [
            ("How does Thirukural define true love and relationships ?", [76, 71, 1109, 1192, 74]),
            ("What are Thirukural's views on the role of women in society?", [58, 907, 910, 57, 909]),
            ("How does Thirukural address the theme of love and its relationship to human emotions?", [111, 79, 80, 1192, 1196])
        ],
        "Personal Growth": [
            ("What advice does Thirukural offer for overcoming adversity ?", [622, 611, 414, 625, 538]),
            ("What lessons does Thirukural offer on the importance of humility?", [985, 125, 963, 978, 95]),
            ("How does Thirukural address the theme of knowledge and its pursuit?", [358, 717, 175, 354, 134])
        ],
        "Leadership and Success": [
            ("Can you provide Thirukural's insights on effective leadership ?", [382, 445, 513, 634, 648]),
            ("What lessons does Thirukural offer on handling success and failure ?", [662, 372, 371, 461, 435]),
            ("What are Thirukural's views on the balance between action and contemplation?", [461, 485, 118, 676, 484])
        ],
        "Philosophy and Nature": [
            ("How does Thirukural address the theme of time and its management?", [334, 484, 333, 337, 712]),
            ("Can you explain Thirukural's perspective on the relationship between humans and nature?", [542, 374, 1323, 149, 898]),
            ("How does Thirukural address the theme of health and its importance?", [946, 949, 987, 217, 330]),
            ("What lessons does Thirukural offer on the balance between work and rest?", [612, 617, 611, 118, 1065])
        ],
        "Career and Finance": [
            ("What advice does Thirukural offer for managing finances?", [333, 512, 657, 478, 408]),
            ("What lessons does Thirukural offer on the importance of hard work?", [611, 619, 1065, 612, 538]),
            ("How does Thirukural address the theme of success and its pursuit?", [179, 371, 611, 31, 542])
        ],
        "Health and Wellness": [
            ("How does Thirukural address the theme of health and its importance?", [946, 949, 987, 217, 330]),
            ("What lessons does Thirukural offer on the balance between work and rest?", [612, 617, 611, 118, 1065])
        ],
        "Ethics and Morality": [
            ("Can you provide Thirukural's insights on the concept of duty and its relationship to morality?", [981, 43, 179, 138, 549]),
            ("What lessons does Thirukural offer on the importance of integrity and honesty?", [134, 138, 296, 48, 952])
        ],
        "Religion and Spirituality": [
            ("How does Thirukural address the theme of faith and its relationship to spirituality?", [134, 311, 542, 24, 1023]),
            ("What lessons does Thirukural offer on the importance of humility and its relationship to faith?", [985, 125, 963, 960, 951])
        ],
        "Politics and Society": [
            ("Can you provide Thirukural's insights on the concept of justice and its relationship to society?", [179, 553, 547, 542, 111]),
            ("What lessons does Thirukural offer on the importance of compassion and its relationship to justice?", [157, 30, 542, 242, 179])
        ],
        "Science and Technology": [
            ("How does Thirukural address the theme of knowledge and its relationship to science and technology?", [358, 134, 717, 1110, 354]),
            ("What lessons does Thirukural offer on the importance of humility and its relationship to knowledge?", [175, 985, 125, 358, 963])
        ],
        "Art and Creativity": [
            ("Can you provide Thirukural's insights on the concept of beauty and its relationship to art and creativity?", [407, 1273, 1101, 1320, 1103]),
            ("What lessons does Thirukural offer on the importance of integrity and its relationship to art?", [138, 134, 131, 30, 32])
        ]
    ]

    var body: some View {
        VStack {
            searchBar
            
            if isSearching {
                ProgressView()
            } else if searchText.isEmpty && !isShowingSearchResults && showSuggestedSearches {
                suggestedSearchesView
            }
        }
    }
    
    private var searchBar: some View {
        HStack {
            TextField("AI Search", text: $searchText, onCommit: performSearch)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            
            Button(action: {
                showSuggestedSearches.toggle() 
            }) {
                Image(systemName: showSuggestedSearches ? "chevron.up" : "chevron.down")
            }
            .padding(.trailing)
            
            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                    isShowingSearchResults = false
                    showSuggestedSearches = false
                }) {
                    Image(systemName: "xmark.circle.fill")
                }
                .padding(.trailing)
            }
        }
    }
    
    private var suggestedSearchesView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                Text("Suggested searches:")
                    .font(.headline)
                    .padding(.horizontal)
                
                ForEach(Array(defaultSearchOptions.keys), id: \.self) { category in
                    categoryView(for: category)
                }
            }
            .padding(.vertical)
        }
    }
    
    private func categoryView(for category: String) -> some View {
        VStack(alignment: .leading) {
            categoryHeader(category)
            
            if expandedCategory == category {
                categoryOptions(for: category)
            }
        }
    }
    
    private func categoryHeader(_ category: String) -> some View {
        Button(action: {
            withAnimation {
                expandedCategory = (expandedCategory == category) ? nil : category
            }
        }) {
            HStack {
                Text(try! TranslationUtil.getTranslation(for: category, to: selectedLanguage) )
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
                Image(systemName: expandedCategory == category ? "chevron.up" : "chevron.down")
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 5)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
    
    private func categoryOptions(for category: String) -> some View {
        ForEach(defaultSearchOptions[category]!, id: \.0) { option in
            Button(action: { 
                searchText = option.0
                Task {
                    let databaseResults = await DatabaseManager.shared.fetchRelatedRows(for: option.1, language: selectedLanguage)
                    originalSearchText = searchText
                    searchResults = databaseResults
                    isShowingSearchResults = true
                }
            }) {
                Text(option.0)
                    .foregroundColor(.primary)
                    .padding(.horizontal)
                    .padding(.vertical, 5)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .transition(.opacity)
    }
}
