
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
        
        sut.load()
        
        XCTAssertEqual(client.requestedURLs, [url])
    }
    
    func test_load_twice_clienRequestsDataFromURLTwice() {
        let url = URL(string: "https://yet-another-url.com")!
        let (sut, client) = makeSUT(url: url)
        
        sut.load()
        sut.load()
        
        XCTAssertEqual(client.requestedURLs, [url, url])
    }
    
    func test_load_deliversConnectivityErrorWhenClientFails() {
        let (sut, client) = makeSUT()
        
        var capturedErrors = [RemoteFeedSuggestedMoviesLoader.Error]()
        sut.load { capturedErrors.append($0) }
        
        let clientError = NSError(domain: "error", code: 400, userInfo: nil)
        client.completesWithError(error: clientError)
        
        XCTAssertEqual(capturedErrors, [.noConnectivity])
    }
    
    // Mark: - Helpers
    
    private func makeSUT(url: URL = URL(string: "https://a-url.com")!) -> (sut: RemoteFeedSuggestedMoviesLoader, client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteFeedSuggestedMoviesLoader(url: url, client: client)
        return (sut, client)
    }
    
    private class HTTPClientSpy: HTTPClient {
        var requestedURLs = [URL]()
        var completions = [((Error) -> Void)]()
        
        func getDataFrom(url: URL, completion: @escaping (Error) -> Void) {
            completions.append(completion)
            requestedURLs.append(url)
        }
        
        func completesWithError(error: NSError, at index: Int = 0) {
            completions[index](error)
        }
    }
}
