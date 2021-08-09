
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
        
        init(from decoder: Decoder) throws {
            let values = try decoder.container(keyedBy: CodingKeys.self)
            let idString = try values.decode(String.self, forKey: .id)
            id = UUID(uuidString: idString)!
            self.title = try values.decode(String.self, forKey: .title)
            self.plot = try values.decode(String.self, forKey: .plot)
            if let posterString = try? values.decode(String.self, forKey: .poster) {
                poster = URL(string: posterString)
            } else {
                poster = nil
            }
        }
    }
    
    static func map(response: HTTPURLResponse, data: Data, completion: @escaping (RemoteFeedSuggestedMoviesLoader.Result) -> ()) {
        guard response.statusCode == 200,
              let items = try? JSONDecoder().decode(RootFeedSuggestedMovies.self, from: data).items else {
            completion(.failure(RemoteFeedSuggestedMoviesLoader.Error.invalidData))
            return
        }
        
        completion(.success(items))
    }
}
