
import Foundation

public final class RemoteFeedSuggestedMoviesLoader: FeedSuggestedMoviesLoader {
    private let url: URL
    private let client: HTTPClient
    
    public enum Error: Swift.Error {
        case noConnectivity
        case invalidData
    }
    
    public typealias Result = FeedSuggestedMoviesLoaderResult
    
    public init(url: URL, client: HTTPClient) {
        self.url = url
        self.client = client
    }
    
    public func load(completion: @escaping (Result) -> ()) {
        client.getDataFrom(url: url) { [weak self] result in
            guard self != nil else { return }
            
            switch result {
            case let .success(response: response, data: data):
                do {
                    let remoteItems = try RemoteFeedSuggestedMoviesParser.map(response: response, data: data)
                    completion(.success(remoteItems.toFeed()))
                } catch {
                    completion(.failure(error))
                }
            case .failure:
                completion(.failure(Error.noConnectivity))
            }
        }
    }
}

private extension Array where Element == RemoteFeedSuggestedMovie {
    func toFeed() -> [FeedSuggestedMovie] {
        map { FeedSuggestedMovie(id: $0.id, title: $0.title, plot: $0.plot, poster: $0.poster) }
    }
}
