
import XCTest
import MovioSuggestedMoviesFeed

class RemoteFeedSuggestedMoviesLoaderTests: XCTestCase {

    func test_init_doesNotRequestDataFromURL() {
        let (_, client) = makeSUT()
        
        XCTAssert(client.requestedURLs.isEmpty)
    }
    
    func test_load_clienRequestsDataFromURL() {
        let url = URL(string: "https://another-url.com")!
        let (sut, client) = makeSUT(url: url)
        
        sut.load { _ in }
        
        XCTAssertEqual(client.requestedURLs, [url])
    }
    
    func test_load_twice_clienRequestsDataFromURLTwice() {
        let url = URL(string: "https://yet-another-url.com")!
        let (sut, client) = makeSUT(url: url)
        
        sut.load { _ in }
        sut.load { _ in }
        
        XCTAssertEqual(client.requestedURLs, [url, url])
    }
    
    func test_load_deliversConnectivityErrorWhenClientFails() {
        let (sut, client) = makeSUT()
        
        var capturedErrors = [RemoteFeedSuggestedMoviesLoader.Error]()
        
        sut.load { errorResult in
            if case let .failure(error) = errorResult {
                capturedErrors.append(error)
            }
        }
        
        let clientError = NSError(domain: "error", code: 0, userInfo: nil)
        client.completesWithError(error: clientError)
        
        XCTAssertEqual(capturedErrors, [.noConnectivity])
    }
    
    func test_load_deliversInvalidDataOnNon200HTTPResponse() {
        let (sut, client) = makeSUT()
        
        let errorSamples = [199,201,300,400,500]
        _ = errorSamples.enumerated().map { (index, errorCode) in
            var capturedErrors = [RemoteFeedSuggestedMoviesLoader.Error]()
            
            sut.load { errorResult in
                if case let .failure(error) = errorResult {
                    capturedErrors.append(error)
                }
            }
            
            client.completesWith(code: errorCode, at: index)
            
            XCTAssertEqual(capturedErrors, [.invalidData])
        }
    }
    
    func test_load_deliversEmptyListWhenReceivingJSONEmptyList() {
        let (sut, client) = makeSUT()
        
        var capturedSuggestedMovies: [FeedSuggestedMovie]?
        sut.load { result in
            if case let .success(movies) = result {
                capturedSuggestedMovies = movies
            }
        }
        
        let jsonResults = ["results": []]
        
        let json = try! JSONSerialization.data(withJSONObject: jsonResults)
        client.completesWith(code: 200, data: json)
        
        XCTAssertNotNil(capturedSuggestedMovies)
    }
    
    func test_load_deliversItemsWhenReceivingJSONWithItems() {
        let (sut, client) = makeSUT()
        
        var capturedSuggestedMovies: [FeedSuggestedMovie]?
        sut.load { result in
            if case let .success(movies) = result {
                capturedSuggestedMovies = movies
            }
        }
        
        let suggestedMovie1 = FeedSuggestedMovie(id: UUID(),
                                                 title: "Star wars",
                                                 plot: "A big story around stars and their wars",
                                                 poster: nil)
        
        let suggestedMovie2 = FeedSuggestedMovie(id: UUID(),
                                                 title: "Shawshenk Redemption",
                                                 plot: "A movie about someone's life in jail and his breakout.",
                                                 poster: URL(string: "http://the-image-url.com")!)
        
        let suggestedMovies = [suggestedMovie1, suggestedMovie2]
        
        let item1json = [
            "id": suggestedMovie1.id.uuidString,
            "title": suggestedMovie1.title,
            "overview": suggestedMovie1.plot
        ]
        
        let item2json = [
            "id": suggestedMovie2.id.uuidString,
            "title": suggestedMovie2.title,
            "overview": suggestedMovie2.plot,
            "poster_path": suggestedMovie2.poster!.absoluteString
        ]
        
        let arrayOfItems = [item1json, item2json]
        
        let jsonResults = ["results": arrayOfItems]
        
        let json = try! JSONSerialization.data(withJSONObject: jsonResults)
        client.completesWith(code: 200, data: json)
        
        XCTAssertNotNil(capturedSuggestedMovies)
        XCTAssertEqual(capturedSuggestedMovies, suggestedMovies)
    }
    
    // Mark: - Helpers
    
    private func makeSUT(url: URL = URL(string: "https://a-url.com")!) -> (sut: RemoteFeedSuggestedMoviesLoader, client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteFeedSuggestedMoviesLoader(url: url, client: client)
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
        
        func completesWith(code: Int, data: Data = Data(), at index: Int = 0) {
            let url = messages[index].url
            let httpResponse = HTTPURLResponse(url: url,
                                               statusCode: code,
                                               httpVersion: nil,
                                               headerFields: nil)!
            
            messages[index].completion(.success(response: httpResponse, data: data))
        }
    }
}
