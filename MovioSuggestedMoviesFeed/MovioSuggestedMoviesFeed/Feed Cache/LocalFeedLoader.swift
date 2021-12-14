
import Foundation

public class LocalFeedLoader {
    private let store: FeedStore
    private let currentDate: () -> Date
    
    public init(store: FeedStore, currentDate: @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
    }
    
    public func save(_ items: [FeedSuggestedMovie], completion: @escaping (Error?) -> Void) {
        store.deleteCache { [unowned self] error in
            guard error == nil else {
                completion(error)
                return
            }
            
            self.store.insert(items: items, timestamp: self.currentDate(), completion: completion)
        }
    }
}
