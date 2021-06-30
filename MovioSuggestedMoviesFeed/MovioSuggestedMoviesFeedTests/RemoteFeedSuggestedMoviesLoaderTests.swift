
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
        let urlToLoad = URL(string: "https://a-url.com")!
        let httpClient = HTTPClientSpy()
        let _ = RemoteFeedSuggestedMoviesLoader(url: urlToLoad, client: httpClient)
        
        XCTAssertNil(httpClient.requestedURL)
    }
    
    func test_load_clientExecutesURLFromRemoteLoader() {
        let urlToLoad = URL(string: "https://a-url.com")!
        let httpClient = HTTPClientSpy()
        let remoteLoader = RemoteFeedSuggestedMoviesLoader(url: urlToLoad, client: httpClient)
        
        remoteLoader.load()
        
        XCTAssertEqual(httpClient.requestedURL, urlToLoad)
    }

}
