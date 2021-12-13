
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
            
            self.store.insert(items: items, timestamp: self.currentDate())
        }
    }
}

class FeedStore {
    typealias DeletionCacheCompletion = (Error?) -> Void
        
    private var deleteCompletions = [DeletionCacheCompletion]()
    
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
    
    func insert(items: [FeedSuggestedMovie], timestamp: Date) {
        receivedMessages.append(.insertion(items, timestamp))
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
        
        var capturedError: Error?
        sut.save(items) { error in
            capturedError = error
        }
        
        store.completeWith(deletionError: deletionError)
        
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
