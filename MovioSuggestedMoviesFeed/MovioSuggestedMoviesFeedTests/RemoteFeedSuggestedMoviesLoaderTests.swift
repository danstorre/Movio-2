
import XCTest

class RemoteFeedSuggestedMoviesLoader {
    let url: URL
    let client: HTTPClient
    
    init(url: URL, client: HTTPClient) {
        self.url = url
        self.client = client
    }
    
    func load() {
        client.getDataFrom(url: url)
    }
}

protocol HTTPClient {
    func getDataFrom(url: URL)
}

class HTTPClientSpy: HTTPClient {
    var requestedURL: URL?
    
    func getDataFrom(url: URL) {
        requestedURL = url
    }
}

class RemoteFeedSuggestedMoviesLoaderTests: XCTestCase {

    func test_init_doesNotRequestDataFromURL() {
        let (_, client) = makeSUT()
        
        XCTAssertNil(client.requestedURL)
    }
    
    func test_load_clientExecutesURLFromRemoteLoader() {
        let url = URL(string: "https://another-url.com")!
        let (sut, client) = makeSUT(url: url)
        
        sut.load()
        
        XCTAssertEqual(client.requestedURL, url)
    }
    
    // Mark: - Helpers
    
    func makeSUT(url: URL = URL(string: "https://a-url.com")!) -> (sut: RemoteFeedSuggestedMoviesLoader, client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteFeedSuggestedMoviesLoader(url: url, client: client)
        return (sut, client)
    }

}
