
import XCTest
import MovioSuggestedMoviesFeed

class LoadFeedFromRemoteUseCaseTests: XCTestCase {

    func test_init_doesNotRequestDataFromURL() {
        let (_, client) = makeSUT()
        
        XCTAssert(client.requestedURLs.isEmpty)
    }
    
    func test_load_clientRequestsDataFromURL() {
        let url = URL(string: "https://another-url.com")!
        let (sut, client) = makeSUT(url: url)
        
        sut.load { _ in }
        
        XCTAssertEqual(client.requestedURLs, [url])
    }
    
    func test_load_twice_clientRequestsDataFromURLTwice() {
        let url = URL(string: "https://yet-another-url.com")!
        let (sut, client) = makeSUT(url: url)
        
        sut.load { _ in }
        sut.load { _ in }
        
        XCTAssertEqual(client.requestedURLs, [url, url])
    }
    
    func test_load_deliversConnectivityErrorWhenClientFails() {
        let (sut, client) = makeSUT()
        
        expect(sut: sut, completesWith: failure(.noConnectivity), when: {
            let clientError = NSError(domain: "error", code: 0, userInfo: nil)
            client.completesWithError(error: clientError)
        })
    }
    
    func test_load_deliversInvalidDataOnNon200HTTPResponse() {
        let (sut, client) = makeSUT()
        
        let errorSamples = [199,201,300,400,500]
        _ = errorSamples.enumerated().map { (index, errorCode) in
            expect(sut: sut, completesWith: failure(.invalidData), when: {
                let json = Data("invalid json".utf8)
                client.completesWith(code: errorCode, data: json, at: index)
            })
        }
    }
    
    func test_load_deliversEmptyListWhenReceivingJSONEmptyList() throws {
        let (sut, client) = makeSUT()

        let json = try makeResultJSON(with: [])
        
        expect(sut: sut, completesWith: .success([]), when: {
            client.completesWith(code: 200, data: json)
        })
    }
    
    func test_load_deliversItemsWhenReceivingJSONWithItems() throws {
        let (sut, client) = makeSUT()

        let (suggestedMovie1, item1json) = makeItem(
            id: UUID(),
            title: "Star wars",
            plot: "A big story around stars and their wars"
        )
        
        let (suggestedMovie2, item2json) = makeItem(
            id: UUID(),
            title: "Shawshenk Redemption",
            plot: "A movie about someone's life in jail and his breakout.",
            poster: URL(string: "http://the-image-url.com")!
        )
        
        let json = try makeResultJSON(with: [item1json, item2json])
        
        let suggestedMovies = [suggestedMovie1, suggestedMovie2]
        
        expect(sut: sut, completesWith: .success(suggestedMovies), when: {
            client.completesWith(code: 200, data: json)
        })
    }
    
    func test_load_doesNotDeliverItemsWhenDeallocated() throws {
        let url = URL(string: "http://a-url.com")!
        let client = HTTPClientSpy()
        var sut: RemoteFeedSuggestedMoviesLoader? = RemoteFeedSuggestedMoviesLoader(url: url, client: client)
        
        var capturedResults = [RemoteFeedSuggestedMoviesLoader.Result]()
        sut?.load {
            capturedResults.append($0)
        }
        sut = nil
        
        client.completesWith(code: 200, data: try makeResultJSON(with: []))
        
        XCTAssertTrue(capturedResults.isEmpty)
    }
    
    // Mark: - Helpers
    private func makeResultJSON(with items: [[String: Any]]) throws -> Data {
        let resultJson = ["results": items]
        return try JSONSerialization.data(withJSONObject: resultJson)
    }
    
    private func makeItem(
        id: UUID,
        title: String,
        plot: String,
        poster: URL? = nil
    ) -> (item: FeedSuggestedMovie, json: [String: Any]) {
        let item = FeedSuggestedMovie(id: id,
                                       title: title,
                                       plot: plot,
                                       poster: poster)
        
        let json = [
            "id": item.id.uuidString,
            "original_title": item.title,
            "overview": item.plot,
            "poster_path": item.poster?.absoluteString
        ].compactMapValues { $0 }
        
        return (item, json)
    }
    
    private func expect(
        sut: RemoteFeedSuggestedMoviesLoader,
        completesWith expectedResults: RemoteFeedSuggestedMoviesLoader.Result,
        when completion: @escaping () -> Void,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let exp = XCTestExpectation(description: "waiting to load items")
        
        sut.load { receivedResults in
            switch (receivedResults, expectedResults) {
            case let (.success(receivedItems), .success(expectedItems)):
                XCTAssertEqual(receivedItems, expectedItems, "expected items to be equal", file: file, line: line)
            case let (.failure(receivedError as RemoteFeedSuggestedMoviesLoader.Error), .failure(expectedError as RemoteFeedSuggestedMoviesLoader.Error)):
                XCTAssertEqual(receivedError, expectedError, "expected errors to be equal", file: file, line: line)
            default:
                XCTFail("received Results are different from the ones expected", file: file, line: line)
            }
            exp.fulfill()
        }
        
        completion()
        
        wait(for: [exp], timeout: 1.0)
    }
    
    private func failure(_ error: RemoteFeedSuggestedMoviesLoader.Error) -> RemoteFeedSuggestedMoviesLoader.Result {
        .failure(error)
    }
    
    private func makeSUT(
        url: URL = URL(string: "https://a-url.com")!,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (sut: RemoteFeedSuggestedMoviesLoader, client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteFeedSuggestedMoviesLoader(url: url, client: client)
        
        trackForMemoryLeak(instance: client, file: file, line: line)
        trackForMemoryLeak(instance: sut, file: file, line: line)
        
        return (sut, client)
    }
    
    private class HTTPClientSpy: HTTPClient {
        var messages = [(url: URL, completion:(HTTPRequestResult) -> Void)]()
        
        var requestedURLs: [URL] {
            messages.map { $0.url }
        }
        
        func getDataFrom(url: URL, completion: @escaping (HTTPRequestResult) -> Void) {
            messages.append((url, completion))
        }
        
        func completesWithError(error: NSError, at index: Int = 0) {
            messages[index].completion(.failure(error: error))
        }
        
        func completesWith(code: Int, data: Data, at index: Int = 0) {
            let url = messages[index].url
            let httpResponse = HTTPURLResponse(url: url,
                                               statusCode: code,
                                               httpVersion: nil,
                                               headerFields: nil)!
            
            messages[index].completion(.success(response: httpResponse, data: data))
        }
    }
}
