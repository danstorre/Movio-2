
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
        sut.load { capturedErrors.append($0) }
        
        let clientError = NSError(domain: "error", code: 400, userInfo: nil)
        client.completesWithError(error: clientError)
        
        XCTAssertEqual(capturedErrors, [.noConnectivity])
    }
    
    func test_load_deliversInvalidDataOnNon200HTTPResponse() {
        let (sut, client) = makeSUT()
        
        let errorSamples = [199,201,300,400,500]
        _ = errorSamples.enumerated().map { (index, sampleError) in
            var capturedErrors = [RemoteFeedSuggestedMoviesLoader.Error]()
            
            sut.load { capturedErrors.append($0) }
            
            client.completesWith(code: sampleError, at: index)
            
            XCTAssertEqual(capturedErrors, [.invalidData])
        }
    }
    
    // Mark: - Helpers
    
    private func makeSUT(url: URL = URL(string: "https://a-url.com")!) -> (sut: RemoteFeedSuggestedMoviesLoader, client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteFeedSuggestedMoviesLoader(url: url, client: client)
        return (sut, client)
    }
    
    private class HTTPClientSpy: HTTPClient {
        var messages = [(url: URL, completion:(Error) -> Void)]()
        
        var requestedURLs: [URL] {
            messages.map { $0.url }
        }
        
        func getDataFrom(url: URL, completion: @escaping (Error) -> Void) {
            messages.append((url, completion))
        }
        
        func completesWithError(error: NSError, at index: Int = 0) {
            messages[index].completion(error)
        }
        
        func completesWith(code: Int, at index: Int = 0) {
        }
    }
}
