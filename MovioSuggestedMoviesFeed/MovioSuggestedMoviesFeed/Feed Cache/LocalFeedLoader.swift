
import Foundation

public final class LocalFeedLoader {
    private let store: FeedStore
    private let currentDate: () -> Date
    
    public typealias SaveResult = Error?
    
    public init(store: FeedStore, currentDate: @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
    }
    
    public func save(_ feed: [FeedSuggestedMovie], completion: @escaping (SaveResult) -> Void) {
        store.deleteCache { [weak self] cacheDeletionError in
            guard let self = self else { return }
            
            guard cacheDeletionError == nil else {
                completion(cacheDeletionError)
                return
            }
            
            self.cache(feed: feed, completion: completion)
        }
    }
    
    private func cache(feed: [FeedSuggestedMovie], completion: @escaping (SaveResult) -> Void) {
        store.insert(feed: feed.toLocal(), timestamp: currentDate(), completion: { [weak self] cacheInsertionError in
            guard self != nil else { return }
            completion(cacheInsertionError)
        })
    }
}

private extension Array where Element == FeedSuggestedMovie {
    func toLocal() -> [LocalFeedSuggestedMovie] {
        self.map { LocalFeedSuggestedMovie(id: $0.id, title: $0.title, plot: $0.plot, poster: $0.poster) }
    }
}
