
import Foundation

internal class RemoteFeedSuggestedMoviesParser {
    private struct RootFeedSuggestedMovies: Decodable {
        public let results: [RemoteFeedSuggestedMovie]
    }
    
    static func map(response: HTTPURLResponse, data: Data) throws -> [RemoteFeedSuggestedMovie] {
        guard response.statusCode == 200,
              let items = try? JSONDecoder().decode(RootFeedSuggestedMovies.self, from: data) else {
            throw RemoteFeedSuggestedMoviesLoader.Error.invalidData
        }
        
        return items.results
    }
}
