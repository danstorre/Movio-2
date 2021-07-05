
import Foundation

internal class RemoteFeedSuggestedMoviesParser {
    private struct RootFeedSuggestedMovies: Decodable {
        private let results: [RemoteFeedSuggestedMovie]
        
        var items: [FeedSuggestedMovie] {
            results.map { $0.feedItems }
        }
    }

    private struct RemoteFeedSuggestedMovie: Decodable {
        private let id: UUID
        private let title: String
        private let plot: String
        private let poster: URL?
        
        private enum CodingKeys: String, CodingKey {
            case id
            case title
            case plot = "overview"
            case poster = "poster_path"
        }
        
        var feedItems: FeedSuggestedMovie {
            FeedSuggestedMovie(id: id, title: title, plot: plot, poster: poster)
        }
    }
    
    static func map(response: HTTPURLResponse, data: Data, completion: @escaping (RemoteFeedSuggestedMoviesLoader.Result) -> ()) {
        guard response.statusCode == 200,
              let items = try? JSONDecoder().decode(RootFeedSuggestedMovies.self, from: data).items else {
            completion(.failure(.invalidData))
            return
        }
        
        completion(.success(items))
    }
}
