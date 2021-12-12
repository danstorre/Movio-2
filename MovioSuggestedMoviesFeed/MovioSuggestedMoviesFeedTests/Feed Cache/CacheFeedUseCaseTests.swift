
import XCTest
import MovioSuggestedMoviesFeed

class LocalFeedLoader {
    private let store: FeedStore
    
    init(store: FeedStore) {
        self.store = store
    }
    
    func save(_ items: [FeedSuggestedMovie], completion: @escaping (Error?) -> Void) {
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
        let (_, store) = makeSUT()
        
        XCTAssertEqual(store.deleteMessagesCount, 0)
    }
    
    func test_save_deletesTheOldCacheFromFeedStore() {
        let items = [uniqueItem(), uniqueItem()]
        let (sut, store) = makeSUT()
        
        sut.save(items) { _ in }
        
        XCTAssertEqual(store.deleteMessagesCount, 1)
    }
    
    func test_save_deliversErrorOnDeletionError() {
        let deletionError = anyNSError()
        let store = FeedStore()
        let sut = LocalFeedLoader(store: store)
        let items = [uniqueItem(), uniqueItem()]
        
        var capturedError: Error?
        sut.save(items) { error in
            capturedError = error
        }
        
        store.completeWith(deletionError: deletionError)
        
        XCTAssertEqual(capturedError as NSError?, deletionError)
    }
    
    // MARK:- Helpers
    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> (sut: LocalFeedLoader, store: FeedStore) {
        let store = FeedStore()
        let sut = LocalFeedLoader(store: store)
        trackForMemoryLeak(instance: store, file: file, line: line)
        trackForMemoryLeak(instance: sut, file: file, line: line)
        return (sut, store)
    }
    
    private func uniqueItem() -> FeedSuggestedMovie {
        return FeedSuggestedMovie(id: UUID(),
                                  title: "any",
                                  plot: "any",
                                  poster: anyURL())
    }
    
    private func anyURL() -> URL {
        URL(string: "http://a-url.com")!
    }
    
    private func anyNSError() -> NSError {
        NSError(domain: "a domain error", code: 1, userInfo: nil)
    }
}
