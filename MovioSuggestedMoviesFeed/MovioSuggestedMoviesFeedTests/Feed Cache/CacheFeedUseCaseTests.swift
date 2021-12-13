
import XCTest
import MovioSuggestedMoviesFeed

class LocalFeedLoader {
    private let store: FeedStore
    private let currentDate: () -> Date
    
    init(store: FeedStore, currentDate: @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
    }
    
    func save(_ items: [FeedSuggestedMovie], completion: @escaping (Error?) -> Void) {
        store.deleteCache { [unowned self] error in
            guard error == nil else {
                completion(error)
                return
            }
            
            self.store.insert(items: items, timestamp: self.currentDate(), completion: completion)
        }
    }
}

class FeedStore {
    typealias DeletionCacheCompletion = (Error?) -> Void
    typealias InsertionCacheCompletion = (Error?) -> Void
        
    private var deleteCompletions = [DeletionCacheCompletion]()
    private var insertCompletions = [InsertionCacheCompletion]()
    
    enum AllMessages: Equatable {
        case deletion
        case insertion([FeedSuggestedMovie], Date)
    }
    
    private(set) var receivedMessages = [AllMessages]()
    
    func deleteCache(completion: @escaping DeletionCacheCompletion) {
        receivedMessages.append(.deletion)
        
        deleteCompletions.append(completion)
    }
    
    func completeWith(deletionError: NSError, at index: Int = 0) {
        deleteCompletions[index](deletionError)
    }
    
    func completeDeletionSuccessfully(at index: Int = 0) {
        deleteCompletions[index](nil)
    }
    
    func insert(items: [FeedSuggestedMovie], timestamp: Date, completion: @escaping InsertionCacheCompletion) {
        receivedMessages.append(.insertion(items, timestamp))
        
        insertCompletions.append(completion)
    }
    
    func completeWith(insertionError: Error, at index: Int = 0) {
        insertCompletions[index](insertionError)
    }
}

class CacheFeedUseCaseTests: XCTestCase {

    func test_init_doesNotMessageTheStoreCacheUponCreation() {
        let (_, store) = makeSUT()
        
        XCTAssertEqual(store.receivedMessages, [])
    }
    
    func test_save_deletesTheOldCacheFromFeedStore() {
        let items = [uniqueItem(), uniqueItem()]
        let (sut, store) = makeSUT()
        
        sut.save(items) { _ in }
        
        XCTAssertEqual(store.receivedMessages, [.deletion])
    }
    
    func test_save_deliversErrorOnDeletionError() {
        let deletionError = anyNSError()
        let (sut, store) = makeSUT()
        let items = [uniqueItem(), uniqueItem()]
        let exp = expectation(description: "wait for deletion to finish.")
        
        var capturedError: Error?
        sut.save(items) { error in
            capturedError = error
            exp.fulfill()
        }
        
        store.completeWith(deletionError: deletionError)
        wait(for: [exp], timeout: 1.0)
        
        XCTAssertEqual(capturedError as NSError?, deletionError)
    }
    
    func test_save_doesNotInsertItemsOnDeletionError() {
        let items = [uniqueItem(), uniqueItem()]
        let (sut, store) = makeSUT()
        let deletionError = anyNSError()
        
        sut.save(items) { _ in }
        store.completeWith(deletionError: deletionError)
        
        XCTAssertEqual(store.receivedMessages, [.deletion])
    }
    
    func test_save_requestsNewCacheInsertionWithTimestampOnSuccessfulDeletion() {
        let items = [uniqueItem(), uniqueItem()]
        let timestamp = Date()
        let (sut, store) = makeSUT(currentDate: { timestamp })
        
        sut.save(items) { _ in }
        store.completeDeletionSuccessfully()
        
        XCTAssertEqual(store.receivedMessages, [.deletion, .insertion(items, timestamp)])
    }
    
    func test_save_failsOnInsertionError() {
        let items = [uniqueItem(), uniqueItem()]
        let timestamp = Date()
        let (sut, store) = makeSUT(currentDate: { timestamp })
        let insertionError = anyNSError()
        let exp = expectation(description: "Wait for save command to finish")
        
        var receivedError: Error?
        sut.save(items) { error in
            receivedError = error
            exp.fulfill()
        }
        
        store.completeDeletionSuccessfully()
        store.completeWith(insertionError: insertionError)
        wait(for: [exp], timeout: 1.0)
        
        XCTAssertEqual(receivedError as NSError?, insertionError)
    }
    
    // MARK:- Helpers
    private func makeSUT(currentDate: @escaping () -> Date = Date.init, file: StaticString = #filePath, line: UInt = #line) -> (sut: LocalFeedLoader, store: FeedStore) {
        let store = FeedStore()
        let sut = LocalFeedLoader(store: store, currentDate: currentDate)
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
