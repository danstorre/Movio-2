
import Foundation

public protocol FeedStore {
    typealias DeletionCacheCompletion = (Error?) -> Void
    typealias InsertionCacheCompletion = (Error?) -> Void
    
    func deleteCache(completion: @escaping DeletionCacheCompletion)
    func insert(feed: [LocalFeedSuggestedMovie], timestamp: Date, completion: @escaping InsertionCacheCompletion)
}
