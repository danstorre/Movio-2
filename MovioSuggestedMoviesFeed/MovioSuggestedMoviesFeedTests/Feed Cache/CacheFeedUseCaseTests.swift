
import XCTest
import MovioSuggestedMoviesFeed

class CacheFeedUseCaseTests: XCTestCase {

    func test_init_doesNotMessageTheStoreCacheUponCreation() {
        let (_, store) = makeSUT()
        
        XCTAssertEqual(store.receivedMessages, [])
    }
    
    func test_save_deletesTheOldCacheFromFeedStore() {
        let feed = [uniqueFeedSuggestedMovie(), uniqueFeedSuggestedMovie()]
        let (sut, store) = makeSUT()
        
        sut.save(feed) { _ in }
        
        XCTAssertEqual(store.receivedMessages, [.deletion])
    }
    
    func test_save_deliversErrorOnDeletionError() {
        let deletionError = anyNSError()
        let (sut, store) = makeSUT()
        
        expect(sut: sut, toCompleteWith: deletionError, when: {
            store.completeWith(deletionError: deletionError)
        })
    }
    
    func test_save_doesNotInsertFeedOnDeletionError() {
        let feed = [uniqueFeedSuggestedMovie(), uniqueFeedSuggestedMovie()]
        let (sut, store) = makeSUT()
        let deletionError = anyNSError()
        
        sut.save(feed) { _ in }
        store.completeWith(deletionError: deletionError)
        
        XCTAssertEqual(store.receivedMessages, [.deletion])
    }
    
    func test_save_requestsNewCacheInsertionWithTimestampOnSuccessfulDeletion() {
        let uniqueFeed = uniqueFeed()
        let timestamp = Date()
        let (sut, store) = makeSUT(currentDate: { timestamp })
        
        sut.save(uniqueFeed.model) { _ in }
        store.completeDeletionSuccessfully()
        
        XCTAssertEqual(store.receivedMessages, [.deletion, .insertion(uniqueFeed.local, timestamp)])
    }
    
    func test_save_failsOnInsertionError() {
        let timestamp = Date()
        let (sut, store) = makeSUT(currentDate: { timestamp })
        let insertionError = anyNSError()
        
        expect(sut: sut, toCompleteWith: insertionError, when: {
            store.completeDeletionSuccessfully()
            store.completeWith(insertionError: insertionError)
        })
    }
    
    func test_save_succeedsOnSuccessfulInsertion() {
        let timestamp = Date()
        let (sut, store) = makeSUT(currentDate: { timestamp })
        
        expect(sut: sut, toCompleteWith: nil, when: {
            store.completeDeletionSuccessfully()
            store.completeInsertionSuccessfully()
        })
    }
    
    func test_save_doesNotDeliverDeletionErrorAfterSUTHasBeenDeallocated() {
        let feed = [uniqueFeedSuggestedMovie(), uniqueFeedSuggestedMovie()]
        let timestamp = Date()
        let store = FeedStoreSpy()
        var sut: LocalFeedLoader? = LocalFeedLoader(store: store, currentDate: { timestamp })
        let deletionError = anyNSError()
        
        var receivedResults = [LocalFeedLoader.SaveResult]()
        sut?.save(feed) { receivedResults.append($0) }
        sut = nil
        
        store.completeWith(deletionError: deletionError)
        
        XCTAssertTrue(receivedResults.isEmpty)
    }
    
    func test_save_doesNotDeliverInsertionErrorAfterSUTHasBeenDeallocated() {
        let feed = [uniqueFeedSuggestedMovie(), uniqueFeedSuggestedMovie()]
        let timestamp = Date()
        let store = FeedStoreSpy()
        var sut: LocalFeedLoader? = LocalFeedLoader(store: store, currentDate: { timestamp })
        let insertionError = anyNSError()
        
        var receivedResults = [LocalFeedLoader.SaveResult]()
        sut?.save(feed) { receivedResults.append($0) }
        
        store.completeDeletionSuccessfully()
        sut = nil
        store.completeWith(insertionError: insertionError)
        
        XCTAssertTrue(receivedResults.isEmpty)
    }
    
    // MARK:- Helpers
    private func expect(sut: LocalFeedLoader, toCompleteWith expectedError: NSError?, when action: () -> Void) {
        let feed = [uniqueFeedSuggestedMovie(), uniqueFeedSuggestedMovie()]
        var receivedError: Error?
        let exp = expectation(description: "Wait for save command to finish")
        
        sut.save(feed) { error in
            receivedError = error
            exp.fulfill()
        }
        
        action()
        wait(for: [exp], timeout: 1.0)
        
        XCTAssertEqual(receivedError as NSError?, expectedError)
    }
    
    private func makeSUT(currentDate: @escaping () -> Date = Date.init, file: StaticString = #filePath, line: UInt = #line) -> (sut: LocalFeedLoader, store: FeedStoreSpy) {
        let store = FeedStoreSpy()
        let sut = LocalFeedLoader(store: store, currentDate: currentDate)
        trackForMemoryLeak(instance: store, file: file, line: line)
        trackForMemoryLeak(instance: sut, file: file, line: line)
        return (sut, store)
    }
    
    private func uniqueFeed() -> (model: [FeedSuggestedMovie], local: [LocalFeedSuggestedMovie]) {
        let model = [uniqueFeedSuggestedMovie(), uniqueFeedSuggestedMovie()]
        let local = model.map { LocalFeedSuggestedMovie(id: $0.id, title: $0.title, plot: $0.plot, poster: $0.poster) }
        
        return (model, local)
    }
    
    private func uniqueFeedSuggestedMovie() -> FeedSuggestedMovie {
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
    
    private class FeedStoreSpy: FeedStore {
        private var deleteCompletions = [DeletionCacheCompletion]()
        private var insertCompletions = [InsertionCacheCompletion]()
        
        enum AllMessages: Equatable {
            case deletion
            case insertion([LocalFeedSuggestedMovie], Date)
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
        
        func insert(feed: [LocalFeedSuggestedMovie], timestamp: Date, completion: @escaping InsertionCacheCompletion) {
            receivedMessages.append(.insertion(feed, timestamp))
            
            insertCompletions.append(completion)
        }
        
        func completeWith(insertionError: Error, at index: Int = 0) {
            insertCompletions[index](insertionError)
        }
        
        func completeInsertionSuccessfully(at index: Int = 0) {
            insertCompletions[index](nil)
        }
    }
}
