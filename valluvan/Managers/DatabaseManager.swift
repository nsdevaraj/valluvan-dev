import Foundation
import SQLite 
import UIKit 
 
public struct DatabaseSearchResult: Identifiable {
    public let id: Int
    public let heading: String
    public let subheading: String
    public let content: String
    public let explanation: String
    public let kuralId: Int
    
    public init(heading: String, subheading: String, content: String, explanation: String, kuralId: Int) {
        self.id = kuralId // Use kuralId as the unique identifier
        self.heading = heading
        self.subheading = subheading
        self.content = content
        self.explanation = explanation
        self.kuralId = kuralId
    }
}

public class DatabaseManager {
    public static let shared = DatabaseManager()
    private var db: Connection?
    public var singletonDb: [(Int, [Float])] = []
    private init() {
        do {
            if let path = Bundle.main.path(forResource: "data", ofType: "sqlite") {
                db = try Connection(path)
                singletonKurals { embeddings in
                    self.singletonDb = embeddings // Store the result in singletonDb
                }
            } else {
                print("Database file not found in the main bundle.")
                print("Searched for 'data.sqlite' in: \(Bundle.main.bundlePath)")
                
                // List contents of the bundle for debugging
                let fileManager = FileManager.default
                if let enumerator = fileManager.enumerator(atPath: Bundle.main.bundlePath) {
                    print("Contents of the main bundle:")
                    while let filePath = enumerator.nextObject() as? String {
                        print(filePath)
                    }
                }
            }
        } catch {
            print("Unable to connect to database: \(error)")
        }
    }

    
    public func getIyals(for pal: String, language: String) async -> [String] {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let self = self else {
                    continuation.resume(returning: [])
                    return
                }

                let tirukkuralTable = Table("tirukkural")
                let kuralId = SQLite.Expression<Int>("kno")
                let palExpr = language == "Tamil" ? SQLite.Expression<String>("pal") : SQLite.Expression<String>("title")
                let iyalExpr = language == "Tamil" ? SQLite.Expression<String>("iyal") : SQLite.Expression<String>("heading")
                
                var iyals: [String] = []
                
                do {
                    let query = tirukkuralTable
                        .select(iyalExpr)
                        .filter(palExpr == pal)
                        .group(iyalExpr)
                        .order(kuralId.asc)
                     
                    for row in try self.db!.prepare(query) {
                        iyals.append(row[iyalExpr])
                    }
                } catch {
                    print("Error fetching iyals: \(error)")
                }
                continuation.resume(returning: iyals)
            }
        }
    }
 
    public func getAdhigarams(for iyal: String, language: String) -> ([String], [Int], [String], [String]) {
        let tirukkuralTable = Table("tirukkural")
        let kuralId = SQLite.Expression<Int>("kno")
        let iyalExpr = language == "Tamil" ? SQLite.Expression<String>("iyal") : SQLite.Expression<String>("heading")
        let adhigaramExpr = language == "Tamil" ? SQLite.Expression<String>("tchapter") : SQLite.Expression<String>("chapter")
        let adhigaramSongExpr = SQLite.Expression<String>("tchapter") 
        var adhigarams: [String] = []
        var kuralIds: [Int] = []
        var adhigaramSongs: [String] = []
        var originalAdhigarams: [String] = []
        do {
            let query = tirukkuralTable
                .select(adhigaramExpr, kuralId, adhigaramSongExpr)
                .filter(iyalExpr == iyal)
                .group(adhigaramExpr)
                .order(kuralId.asc)
            
            for row in try db!.prepare(query) {
                adhigarams.append(row[adhigaramExpr])   
                originalAdhigarams.append(row[adhigaramExpr])
                kuralIds.append(row[kuralId])
                adhigaramSongs.append(row[adhigaramSongExpr])
            }
        } catch {
            print("Error fetching adhigarams: \(error)")
        }

        return (adhigarams, kuralIds, adhigaramSongs, originalAdhigarams)
    } 

    public func getSingleLine(for adhigaram: String, language: String) -> [String] {
        let tirukkuralTable = Table("tirukkural")
        let kuralId = SQLite.Expression<Int>("kno") 
        let adhigaramExpr = SQLite.Expression<String>("chapter")
        
        let firstLineExpr = SQLite.Expression<String>(language) 
         
        var kurals: [String] = []
        do {
            let query = tirukkuralTable
                .select(kuralId, firstLineExpr)   
                .filter(adhigaramExpr == adhigaram)
                .order(kuralId.asc)  

            for row in try db!.prepare(query) {
                kurals.append(String(row[kuralId]) + " " + row[firstLineExpr]) 
            }
        } catch {
            print("Error fetching first line: \(error)")
        }
        return kurals
    }

    public func getFirstLine(for adhigaram: String, language: String) -> [String] {
        let tirukkuralTable = Table("tirukkural")
        let kuralId = SQLite.Expression<Int>("kno") 
        let adhigaramExpr = language == "Tamil" ? SQLite.Expression<String>("tchapter") : SQLite.Expression<String>("chapter")
        
        let firstLineExpr: SQLite.Expression<String>
        let secondLineExpr: SQLite.Expression<String>
        
        switch language {
        case "Tamil":
            firstLineExpr = SQLite.Expression<String>("firstline")
            secondLineExpr = SQLite.Expression<String>("secondline")
        case "telugu":
            firstLineExpr = SQLite.Expression<String>("telugu1")
            secondLineExpr = SQLite.Expression<String>("telugu2")
        case "hindi":
            firstLineExpr = SQLite.Expression<String>("hindi1")
            secondLineExpr = SQLite.Expression<String>("hindi2")
        default:
            firstLineExpr = SQLite.Expression<String>("efirstline")
            secondLineExpr = SQLite.Expression<String>("esecondline")
        }
        
        var kurals: [String] = []
        do {
            let query = tirukkuralTable
                .select(kuralId, firstLineExpr, secondLineExpr)   
                .filter(adhigaramExpr == adhigaram)
                .order(kuralId.asc)  

            for row in try db!.prepare(query) {
                kurals.append(String(row[kuralId]) + " " + row[firstLineExpr])
                kurals.append(row[secondLineExpr])
            }
        } catch {
            print("Error fetching first line: \(error)")
        }
        return kurals
    }
    
    func getExplanation(for kuralId: Int, language: String) -> NSAttributedString {
        let tirukkuralTable = Table("tirukkural")
        let kuralIdExpr = SQLite.Expression<Int>("kno")
        let explanationExpr: SQLite.Expression<String>
        let manaExplanationExpr: SQLite.Expression<String>
        let pariExplanationExpr: SQLite.Expression<String>
        let varaExplanationExpr: SQLite.Expression<String>
        let popsExplanationExpr: SQLite.Expression<String>
        let muniExplanationExpr: SQLite.Expression<String>
        let puliExplanationExpr: SQLite.Expression<String>
        let devExplanationExpr: SQLite.Expression<String>
        let namaExplanationExpr: SQLite.Expression<String>
        let tamilExplanationExpr: SQLite.Expression<String>
        var query: Table
        var attributedExplanation = NSMutableAttributedString()

        switch language {
        case "Tamil":
            explanationExpr = SQLite.Expression<String>("kalaignar")
            manaExplanationExpr = SQLite.Expression<String>("manakudavar")
            pariExplanationExpr = SQLite.Expression<String>("parimelazhagar")
            varaExplanationExpr = SQLite.Expression<String>("varadarajanar")
            popsExplanationExpr = SQLite.Expression<String>("salomon")
            muniExplanationExpr = SQLite.Expression<String>("munisamy")
            puliExplanationExpr = SQLite.Expression<String>("puliur")
            devExplanationExpr = SQLite.Expression<String>("devaneya")
            namaExplanationExpr = SQLite.Expression<String>("namakkal")
            tamilExplanationExpr = SQLite.Expression<String>("tamilkuzavi")
            query = tirukkuralTable
                .select(explanationExpr, manaExplanationExpr, pariExplanationExpr, varaExplanationExpr, popsExplanationExpr, muniExplanationExpr, puliExplanationExpr, devExplanationExpr, namaExplanationExpr, tamilExplanationExpr )
                .filter(kuralIdExpr == kuralId) 
            do {                
                if let row = try db!.pluck(query) {
                    let boldAttributes: [NSAttributedString.Key: Any] = [.font: UIFont.boldSystemFont(ofSize: UIFont.systemFontSize)]
                    appendExplanation(to: &attributedExplanation, title: "கலைஞர் விளக்கம்: ", content: "\n"+row[explanationExpr]+"\n", boldAttributes: boldAttributes)
                    appendExplanation(to: &attributedExplanation, title: "மணக்குடவர் விளக்கம்: ", content: "\n"+row[manaExplanationExpr]+"\n", boldAttributes: boldAttributes)
                    appendExplanation(to: &attributedExplanation, title: "பரிமேலழகர் விளக்கம்: ", content: "\n"+row[pariExplanationExpr]+"\n", boldAttributes: boldAttributes)
                    appendExplanation(to: &attributedExplanation, title: "மு. வரதராசன் விளக்கம்: ", content: "\n"+row[varaExplanationExpr]+"\n", boldAttributes: boldAttributes)
                    appendExplanation(to: &attributedExplanation, title: "சாலமன் பாப்பையா விளக்கம்: ", content: "\n"+row[popsExplanationExpr]+"\n", boldAttributes: boldAttributes)
                    appendExplanation(to: &attributedExplanation, title: "வ. முனிசாமி விளக்கம்: ", content: "\n"+row[muniExplanationExpr]+"\n", boldAttributes: boldAttributes)
                    appendExplanation(to: &attributedExplanation, title: "புலியூர் கேசிகன் விளக்கம்: ", content: "\n"+row[puliExplanationExpr]+"\n", boldAttributes: boldAttributes)
                    appendExplanation(to: &attributedExplanation, title: "தேவநேயப் பாவாணர் விளக்கம்: ", content: "\n"+row[devExplanationExpr]+"\n", boldAttributes: boldAttributes)
                    appendExplanation(to: &attributedExplanation, title: "நாமக்கல் கவிஞர் விளக்கம்: ", content: "\n"+row[namaExplanationExpr]+"\n", boldAttributes: boldAttributes)
                    appendExplanation(to: &attributedExplanation, title: "தமிழ்க்குழவி விளக்கம்: ", content: "\n"+row[tamilExplanationExpr]+"\n", boldAttributes: boldAttributes, isLast: true)
                         
                }
            } catch {
                print("Error fetching Tamil explanation: \(error)")
            }   
        default:
            explanationExpr = SQLite.Expression<String>("explanation") 
            do {                 
                query = tirukkuralTable
                    .select(explanationExpr)
                    .filter(kuralIdExpr == kuralId) 
                
                if let row = try db!.pluck(query) {
                    attributedExplanation = NSMutableAttributedString(string: row[explanationExpr])
                }
            } catch {
                print("Error fetching explanation: \(error)")
            } 
        }
        return attributedExplanation
    }

    private func appendExplanation(to attributedString: inout NSMutableAttributedString, title: String, content: String, boldAttributes: [NSAttributedString.Key: Any], isLast: Bool = false) {
        attributedString.append(NSAttributedString(string: title, attributes: boldAttributes))
        attributedString.append(NSAttributedString(string: content))
        if !isLast {
            attributedString.append(NSAttributedString(string: "\n\n"))
        }
    }

    func searchContent(query: String, language: String) -> [DatabaseSearchResult] {
        var results: [DatabaseSearchResult] = []
        let searchQuery: String
        let searchPattern = "%\(query)%"

        if language != "English" && language != "telugu" && language != "hindi" {
            searchQuery = """
                SELECT "kno", "heading", "chapter", "efirstline", "esecondline", "explanation", "\(language)"
                FROM tirukkural
                WHERE "heading" LIKE ? OR "chapter" LIKE ? OR "efirstline" LIKE ? OR "esecondline" LIKE ? OR "explanation" LIKE ? OR "\(language)" LIKE ?
                LIMIT 20
            """
            
            do {
                let rows = try db!.prepare(searchQuery, searchPattern, searchPattern, searchPattern, searchPattern, searchPattern, searchPattern)
                for row in rows {
                    let result = DatabaseSearchResult(
                        heading: row[1] as? String ?? "",
                        subheading: row[2] as? String ?? "",
                        content: "\(row[6] as? String ?? "")\n\(row[3] as? String ?? "")\n\(row[4] as? String ?? "")",
                        explanation: row[5] as? String ?? "",
                        kuralId: Int(row[0] as? Int64 ?? 0)
                    )
                    results.append(result)
                }
            } catch {
                print("Error searching content: \(error.localizedDescription)")
            }    
        } else {
            if language == "English" {
                searchQuery = """
                    SELECT "kno", "heading", "chapter", "efirstline", "esecondline", "explanation"
                    FROM tirukkural
                    WHERE "heading" LIKE ? OR "chapter" LIKE ? OR "efirstline" LIKE ? OR "esecondline" LIKE ? OR "explanation" LIKE ?
                    LIMIT 20
                """
            } else {
                searchQuery = """
                    SELECT "kno", "heading", "chapter", "\(language)1", "\(language)2", "explanation"
                    FROM tirukkural
                    WHERE "heading" LIKE ? OR "chapter" LIKE ? OR "\(language)1" LIKE ? OR "\(language)2" LIKE ? OR "explanation" LIKE ?
                    LIMIT 20
                """
            }
            do {
                let rows = try db!.prepare(searchQuery, searchPattern, searchPattern, searchPattern, searchPattern, searchPattern)
                for row in rows {
                    let result = DatabaseSearchResult(
                        heading: row[1] as? String ?? "",
                        subheading: row[2] as? String ?? "",
                        content: "\(row[3] as? String ?? "")\n\(row[4] as? String ?? "")",
                        explanation: row[5] as? String ?? "",
                        kuralId: Int(row[0] as? Int64 ?? 0)
                    )
                    results.append(result)
                }
            } catch {
                print("Error searching content: \(error.localizedDescription)")
            }
        }

        return results
    }


    func searchTamilContent(query: String) -> [DatabaseSearchResult] {
        var results: [DatabaseSearchResult] = []
        let searchQuery = """
            SELECT "kno", "iyal", "tchapter", "firstline", "secondline", "manakudavar", "parimelazhagar", "varadarajanar", "kalaignar", "salomon", "munisamy", "efirstline", "esecondline", "explanation"
            FROM tirukkural
            WHERE "iyal" LIKE ? OR "tchapter" LIKE ? OR "firstline" LIKE ? OR "secondline" LIKE ? OR "manakudavar" LIKE ? OR "parimelazhagar" LIKE ? OR "varadarajanar" LIKE ? OR "kalaignar" LIKE ? OR "salomon" LIKE ? OR "munisamy" LIKE ? OR "efirstline" LIKE ? OR "esecondline" LIKE ? OR "explanation" LIKE ?
            LIMIT 20
        """
        let searchPattern = "%\(query)%"

        do {
            let rows = try db!.prepare(searchQuery, searchPattern, searchPattern, searchPattern, searchPattern, searchPattern, searchPattern, searchPattern, searchPattern, searchPattern, searchPattern, searchPattern, searchPattern, searchPattern)
            for row in rows {
                let result = DatabaseSearchResult(
                    heading: row[1] as? String ?? "",
                    subheading: row[2] as? String ?? "",
                    content: "\(row[3] as? String ?? "")\n\(row[4] as? String ?? "")",
                    explanation: row[8] as? String ?? "",
                    kuralId: Int(row[0] as? Int64 ?? 0)
                )
                results.append(result)
            }
        } catch {
            print("Error searching Tamil content: \(error.localizedDescription)")
        }

        return results
    }

    func getKuralById(_ kuralId: Int, language: String) -> DatabaseSearchResult? {
        let tirukkuralTable = Table("tirukkural")
        let kuralIdExpr = SQLite.Expression<Int>("kno")
        let headingExpr = SQLite.Expression<String>("heading")
        let subheadingExpr = SQLite.Expression<String>("chapter")
        let contentExpr1 = SQLite.Expression<String>("firstline")
        let contentExpr2 = SQLite.Expression<String>("secondline")
        let tfirstLineExpr = SQLite.Expression<String>("telugu1")
        let tsecondLineExpr = SQLite.Expression<String>("telugu2")
        let hfirstLineExpr = SQLite.Expression<String>("hindi1")
        let hsecondLineExpr = SQLite.Expression<String>("hindi2")
        let explanationExpr: SQLite.Expression<String>
        
        switch language {
        case "Tamil":
            explanationExpr = SQLite.Expression<String>("kalaignar")
        case "English", "hindi", "telugu":
            explanationExpr = SQLite.Expression<String>("explanation")
        default:
            explanationExpr = SQLite.Expression<String>(language)
        }

        do {
            let query = tirukkuralTable
                .select(headingExpr, subheadingExpr, contentExpr1, contentExpr2, tfirstLineExpr, tsecondLineExpr, hfirstLineExpr, hsecondLineExpr, explanationExpr)
                .filter(kuralIdExpr == kuralId)

            if let row = try db!.pluck(query) {
                return DatabaseSearchResult(
                    heading: row[headingExpr],
                    subheading: row[subheadingExpr],
                    content: language == "telugu" ? "\(row[tfirstLineExpr])\n\(row[tsecondLineExpr])" : language == "hindi" ? "\(row[hfirstLineExpr])\n\(row[hsecondLineExpr])" : "\(row[contentExpr1])\n\(row[contentExpr2])",
                    explanation: row[explanationExpr],
                    kuralId: kuralId
                )
            }
        } catch {
            print("Error fetching Kural by ID: \(error)")
        }

        return nil
    }
    
    func hexStringTofloatArray(_ hex: String) -> [Float]? {
        var floatArray: [Float] = []
        let strhex = String(hex.dropFirst().dropLast())
        let chars = Array(strhex)
        
        // Ensure the hex string length is a multiple of 8
        guard chars.count % 8 == 0 else {
            print("Hex string length is not a multiple of 8")
            return nil
        }
        
        for i in stride(from: 0, to: chars.count, by: 8) {
            let hexString = String(chars[i..<min(i + 8, chars.count)])
            
            // Convert hex string to Data
            var byteArray = [UInt8]()
            for j in stride(from: 0, to: hexString.count, by: 2) {
                let startIndex = hexString.index(hexString.startIndex, offsetBy: j)
                let endIndex = hexString.index(startIndex, offsetBy: 2)
                let byteString = String(hexString[startIndex..<endIndex])
                if let byte = UInt8(byteString, radix: 16) {
                    byteArray.append(byte)
                } else {
                    print("Failed to convert hex string to byte: \(byteString)")
                    return nil
                }
            }
            
            // Create Data from byte array
            let data = Data(byteArray)
            
            // Ensure data has enough bytes to load a Float
            guard data.count >= MemoryLayout<Float>.size else {
                print("Data does not contain enough bytes to load a Float")
                return nil
            }
            
            let float = data.withUnsafeBytes { $0.load(as: Float.self) }
            floatArray.append(float)
        }  
        return floatArray
    }

    func processEmbeddingBinding(_ embeddingBinding: Any) -> [Float]? {
        // Convert the binding to a string representation
        let hexString = String(describing: embeddingBinding)
            .replacingOccurrences(of: "Optional(x'", with: "")
            .replacingOccurrences(of: "')", with: "")
            .replacingOccurrences(of: " ", with: ""); // Remove any spaces if present
        
        // Check if the hex string is valid
        guard !hexString.isEmpty else {
            print("Hex string is empty after cleaning")
            return nil
        }
        
        // Ensure the hex string does not start with 'x'
        let cleanedHexString = hexString.replacingOccurrences(of: "x", with: "")
        
        // Convert hex string to byte array
        return hexStringTofloatArray(cleanedHexString)
    }

    public func singletonKurals(completion: @escaping ([(Int, [Float])]) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let query = "SELECT kno, embeddings FROM tirukkural WHERE embeddings IS NOT NULL"
            var allEmbeddings: [(Int, [Float])] = []
            do {
                let rows = try self.db!.prepare(query)
                
                for row in rows {
                    if let idValue = row[0] as? Int64 {
                        let id = Int(idValue)
                        var floatArray: [Float] = []
                        if let embeddingBinding = row[1] { 
                            floatArray = self.processEmbeddingBinding(embeddingBinding) ?? []
                            allEmbeddings.append((id, floatArray)) 
                        } else {
                            print("Failed to cast row[1] to Binding")
                            return
                        }
                    }
                } 
            } catch {
                print("Error fetching related kurals: \(error)")
            }        
            print("allEmbeddings")
            completion(allEmbeddings)
        }
    }

    public func findRelatedKurals(for kuralId: Int, topN: Int = 5) -> [DatabaseSearchResult] { 
        var relatedKurals: [DatabaseSearchResult] = [] 
        let tirukkuralTable = Table("tirukkural")
        let kuralIdExpr = SQLite.Expression<Int>("kno") 
        let embeddingsExpr = SQLite.Expression<Blob>("embeddings") 
        
        var targetEmbedding: [Float]? 
        do {
            let query = tirukkuralTable
                .select(kuralIdExpr, embeddingsExpr)    
                .filter(kuralIdExpr == kuralId) 

            for row in try db!.prepare(query) { 
                if let embeddingBinding = row[embeddingsExpr] as? Blob { // Ensure embeddingBinding is of type Blob
                    targetEmbedding = processEmbeddingBinding(embeddingBinding) ?? [] // Unwrap and provide a default value
                } else {
                    print("Failed to cast row[1] to Binding")
                    return []
                }
            } 
        } catch {
            print("Error fetching targetEmbedding line: \(error)")
        }
        
        // Safely unwrap targetEmbedding
        guard let unwrappedTargetEmbedding = targetEmbedding else {
            print("Target embedding is nil")
            return [] // Return an empty array if targetEmbedding is nil
        }
        
        do {
            let allEmbeddings: [(Int, [Float])] = singletonDb  
            let similarities = allEmbeddings.map { (id, embedding) -> (Int, Float) in
                let similarity = cosineSimilarity(v1: unwrappedTargetEmbedding, v2: embedding) 
                return (id, similarity)
            }
            
            let sortedSimilarities = similarities.sorted { $0.1 > $1.1 }.prefix(topN)
            let relatedIds = sortedSimilarities.map { $0.0 }
            print(relatedIds, "relatedIds")
            let relatedQuery = "SELECT kno, heading, chapter, efirstline, esecondline, explanation FROM tirukkural WHERE kno IN (\(relatedIds.map { String($0) }.joined(separator: ",")))"
            let relatedRows = try db!.prepare(relatedQuery)
            
            for row in relatedRows {
                if let kuralIdValue = row[0] as? Int64 {
                    let result = DatabaseSearchResult(
                        heading: row[1] as? String ?? "",
                        subheading: row[2] as? String ?? "",
                        content: "\(row[3] as? String ?? "")\n\(row[4] as? String ?? "")",
                        explanation: row[5] as? String ?? "",
                        kuralId: Int(kuralIdValue) // Convert Int64 to Int
                    )
                    relatedKurals.append(result)
                } else {
                    print("Kural ID is not of type Int64")
                }
            } 
        } catch {
            print("Error fetching related kurals: \(error)")
        }
        
        return relatedKurals
    }
    
    private func cosineSimilarity(v1: [Float], v2: [Float]) -> Float {
        let dotProduct = zip(v1, v2).map(*).reduce(0, +)
        let magnitude1 = sqrt(v1.map { $0 * $0 }.reduce(0, +))
        let magnitude2 = sqrt(v2.map { $0 * $0 }.reduce(0, +))
        return dotProduct / (magnitude1 * magnitude2)
    }
}
