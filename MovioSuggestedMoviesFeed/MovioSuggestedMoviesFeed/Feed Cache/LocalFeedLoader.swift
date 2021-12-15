
import Foundation

public final class LocalFeedLoader {
    private let store: FeedStore
    private let currentDate: () -> Date
    
    public init(store: FeedStore, currentDate: @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
    }
    
    public func save(_ items: [FeedSuggestedMovie], completion: @escaping (Error?) -> Void) {
        store.deleteCache { [weak self] cacheDeletionError in
            guard let self = self else { return }
            
            guard cacheDeletionError == nil else {
                completion(cacheDeletionError)
                return
            }
            
            self.cache(items: items, completion: completion)
        }
    }
    
    private func cache(items: [FeedSuggestedMovie], completion: @escaping (Error?) -> Void) {
        store.insert(items: items, timestamp: currentDate(), completion: { [weak self] cacheInsertionError in
            guard self != nil else { return }
            completion(cacheInsertionError)
        })
    }
}
