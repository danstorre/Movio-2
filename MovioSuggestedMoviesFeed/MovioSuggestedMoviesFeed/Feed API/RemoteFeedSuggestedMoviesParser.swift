
import Foundation

internal struct RemoteFeedSuggestedMovie: Decodable {
    public let id: UUID
    public let title: String
    public let plot: String
    public let poster: URL?
    
    private enum CodingKeys: String, CodingKey {
        case id
        case title = "original_title"
        case plot = "overview"
        case poster = "poster_path"
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let idNumber = try values.decode(String.self, forKey: .id)
        id = UUID(uuidString: String(describing: idNumber))!
        self.title = try values.decode(String.self, forKey: .title)
        self.plot = try values.decode(String.self, forKey: .plot)
        if let posterString = try? values.decode(String.self, forKey: .poster) {
            poster = URL(string: posterString)
        } else {
            poster = nil
        }
    }
}

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
