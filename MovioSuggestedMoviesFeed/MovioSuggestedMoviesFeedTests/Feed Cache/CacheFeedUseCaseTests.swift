
import XCTest

class LocalFeedLoader {
    private let store: FeedStore
    
    init(store: FeedStore) {
        self.store = store
    }
    
    func save() {
        store.deleteCache()
    }
}

class FeedStore {
    var deleteMessagesCount = 0
    
    func deleteCache() {
        deleteMessagesCount += 1
    }
}

class CacheFeedUseCaseTests: XCTestCase {

    func test_init_doesNotMessageToTheFeedStore() {
        let store = FeedStore()
        let _ = LocalFeedLoader(store: store)
        
        XCTAssertEqual(store.deleteMessagesCount, 0)
    }
    
    func test_save_deletesTheOldCacheFromFeedStore() {
        let store = FeedStore()
        let sut = LocalFeedLoader(store: store)
        
        sut.save()
        
        XCTAssertEqual(store.deleteMessagesCount, 1)
    }
}
