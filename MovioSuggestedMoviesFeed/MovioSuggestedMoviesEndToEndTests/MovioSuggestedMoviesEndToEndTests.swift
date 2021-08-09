
import XCTest
import MovioSuggestedMoviesFeed

class MovioSuggestedMoviesEndToEndTests: XCTestCase {

    func test_endToEndServerGETSuggestedMoviesResult_matchesTheMoviesTestData () {
        let testURL = URL(string: "http://a-url.com")!
        let client = URLSessionHTTPClient()
        let _ = RemoteFeedSuggestedMoviesLoader(url: testURL, client: client)
    }

}
