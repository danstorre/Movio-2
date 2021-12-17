
import Foundation

public protocol FeedStore {
    typealias DeletionCacheCompletion = (Error?) -> Void
    typealias InsertionCacheCompletion = (Error?) -> Void
    
    func deleteCache(completion: @escaping DeletionCacheCompletion)
    func insert(items: [LocalFeedSuggestedMovie], timestamp: Date, completion: @escaping InsertionCacheCompletion)
}

public struct LocalFeedSuggestedMovie: Equatable {
    public let id: UUID
    public let title: String
    public let plot: String
    public let poster: URL?
    
    public init(id: UUID, title: String, plot: String, poster: URL? = nil) {
        self.id = id
        self.title = title
        self.plot = plot
        self.poster = poster
    }
}
