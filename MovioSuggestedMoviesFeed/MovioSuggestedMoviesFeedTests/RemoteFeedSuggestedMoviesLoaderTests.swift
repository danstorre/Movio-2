
import XCTest

class RemoteFeedSuggestedMoviesLoader {
    let url: URL
    let client: HTTPClient
    
    init(url: URL, client: HTTPClient) {
        self.url = url
        self.client = client
    }
}

class HTTPClient {
    var requestedURL: URL?
}

class RemoteFeedSuggestedMoviesLoaderTests: XCTestCase {

    func test_init_doesNotRequestDataFromURL() {
        let urlToLoad = URL(string: "https://a-url.com")!
        let httpClient = HTTPClient()
        let _ = RemoteFeedSuggestedMoviesLoader(url: urlToLoad, client: httpClient)
        
        XCTAssertNil(httpClient.requestedURL)
    }

}
