
import XCTest

class LocalFeedLoader {
    private let store: FeedStore
    
    init(store: FeedStore) {
        self.store = store
    }
}

class FeedStore {
    var messagesCount = 0
}

class CacheFeedUseCaseTests: XCTestCase {

    func test_init_doesNotMessageToTheStore() {
        let store = FeedStore()
        let _ = LocalFeedLoader(store: store)
        
        XCTAssertEqual(store.messagesCount, 0)
    }
}
