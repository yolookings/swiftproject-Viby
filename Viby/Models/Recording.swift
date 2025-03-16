import Foundation

struct Recording {
    let id: UUID
    let url: URL
    let timestamp: Date
    var title: String
    
    init(id: UUID = UUID(), url: URL, timestamp: Date = Date(), title: String = "Rekaman Baru") {
        self.id = id
        self.url = url
        self.timestamp = timestamp
        self.title = title
    }
} 