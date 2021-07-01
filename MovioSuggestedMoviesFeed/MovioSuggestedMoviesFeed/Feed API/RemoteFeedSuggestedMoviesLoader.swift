import Foundation

public enum HTTPRequestResult {
    case success(response: HTTPURLResponse, data: Data)
    case failure(error: Error)
}

public protocol HTTPClient {
    func getDataFrom(url: URL, completion: @escaping (HTTPRequestResult) -> Void)
}

public final class RemoteFeedSuggestedMoviesLoader {
    private let url: URL
    private let client: HTTPClient
    
    public enum Error: Swift.Error {
        case noConnectivity
        case invalidData
    }
    
    public enum Result: Equatable {
        case success([FeedSuggestedMovie])
        case failure(Error)
    }
    
    public init(url: URL, client: HTTPClient) {
        self.url = url
        self.client = client
    }
    
    public func load(completion: @escaping (Result) -> ()) {
        client.getDataFrom(url: url) { result in
            switch result {
            case let .success(response: response, data: data):
                do {
                    let items = try RemoteFeedSuggestedMoviesParser.parse(data: data,
                                                                          response: response)
                    completion(.success(items))
                } catch {
                    completion(.failure(.invalidData))
                }
            case .failure:
                completion(.failure(.noConnectivity))
            }
        }
    }
}

private class RemoteFeedSuggestedMoviesParser {
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
    
    static func parse(data: Data, response: HTTPURLResponse) throws -> [FeedSuggestedMovie] {
        guard response.statusCode == 200 else {
            throw RemoteFeedSuggestedMoviesLoader.Error.invalidData
        }
        
        return try JSONDecoder().decode(RootFeedSuggestedMovies.self, from: data).items
    }
}
