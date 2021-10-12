
import XCTest
import MovioSuggestedMoviesFeed

class MovioSuggestedMoviesEndToEndTests: XCTestCase {

    func test_endToEndServerGETSuggestedMoviesResult_matchesTheMoviesTestData () {
        switch suggestedMoviesResult() {
        case let .success(items)?:
            XCTAssertEqual(items.count, 2)
            
            XCTAssertEqual(items[0], expectedItem(at: 0))
            XCTAssertEqual(items[1], expectedItem(at: 1))
            
        case let .failure(error)?:
            XCTFail("Expected result to be successful, got \(error) instead")
        default:
            XCTFail("Expected result to be successful, got no result instead")
        }
    }
    
    // MARK: Helper methods
    private func suggestedMoviesResult() -> FeedSuggestedMoviesLoaderResult? {
        let testURL = URL(string: "https://movio.free.beeceptor.com/suggestedMovies")!
        let client = URLSessionHTTPClient(session: URLSession(configuration: .ephemeral))
        let remoteSuggestedMovies = RemoteFeedSuggestedMoviesLoader(url: testURL, client: client)
        
        let exp = expectation(description: "wait for completion from the remote")
        var receivedResult: FeedSuggestedMoviesLoaderResult?
        
        remoteSuggestedMovies.load { result in
            receivedResult = result
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 15.0)
        return receivedResult
    }
    
    private func expectedItem(at index: Int) -> FeedSuggestedMovie {
        FeedSuggestedMovie(id: id(at: index),
                           title: title(at: index),
                           plot: plot(at: index),
                           poster: poster(at: index))
    }
    
    private func id(at index: Int) -> UUID {
        UUID(uuidString:
                [
                    "68753A44-4D6F-1226-9C60-0050E4C00092",
                    "68753A44-4D6F-1226-9C60-0050E4C00091"
                ][index])!
    }

    private func title(at index: Int) -> String {
        [
            "One Direction: This Is Us",
            "On the Waterfront"
        ][index]
    }
    
    private func poster(at index: Int) -> URL? {
        [
            nil,
            nil
        ][index]
    }
    
    private func plot(at index: Int) -> String {
        [
            "Go behind the scenes during One Directions sell out \"Take Me Home\" tour and experience life on the road.",
            ""
        ][index]
    }
}
