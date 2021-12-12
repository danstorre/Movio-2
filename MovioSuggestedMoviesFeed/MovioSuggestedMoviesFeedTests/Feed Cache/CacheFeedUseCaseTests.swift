
import XCTest

class LocalFeedLoader {
    private let store: FeedStore
    
    init(store: FeedStore) {
        self.store = store
    }
    
    func save(completion: @escaping (Error?) -> Void) {
        store.deleteCache(completion: completion)
    }
}

class FeedStore {
    typealias DeletionCacheCompletion = (Error?) -> Void
    
    var deleteMessagesCount = 0
    
    private var deleteCompletions = [DeletionCacheCompletion]()
    
    func deleteCache(completion: @escaping DeletionCacheCompletion) {
        deleteMessagesCount += 1
        
        deleteCompletions.append(completion)
    }
    
    func completeWith(deletionError: NSError, at index: Int = 0) {
        deleteCompletions[index](deletionError)
    }
}

class CacheFeedUseCaseTests: XCTestCase {

    func test_init_doesNotDeleteTheCacheUponCreation() {
        let store = FeedStore()
        let _ = LocalFeedLoader(store: store)
        
        XCTAssertEqual(store.deleteMessagesCount, 0)
    }
    
    func test_save_deletesTheOldCacheFromFeedStore() {
        let store = FeedStore()
        let sut = LocalFeedLoader(store: store)
        
        sut.save() { _ in}
        
        XCTAssertEqual(store.deleteMessagesCount, 1)
    }
    
    func test_save_deliversErrorOnDeletionError() {
        let deletionError = anyNSError()
        let store = FeedStore()
        let sut = LocalFeedLoader(store: store)
        
        var capturedError: Error?
        sut.save() { error in
            capturedError = error
        }
        
        store.completeWith(deletionError: deletionError)
        
        XCTAssertEqual(capturedError as NSError?, deletionError)
    }
    
    // MARK:- Helpers
    
    private func anyNSError() -> NSError {
        NSError(domain: "a domain error", code: 1, userInfo: nil)
    }
}
