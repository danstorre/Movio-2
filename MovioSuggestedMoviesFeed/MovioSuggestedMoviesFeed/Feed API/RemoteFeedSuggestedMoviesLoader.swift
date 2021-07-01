import Foundation

public protocol HTTPClient {
    func getDataFrom(url: URL, completion: @escaping (Error) -> Void)
}

public final class RemoteFeedSuggestedMoviesLoader {
    private let url: URL
    private let client: HTTPClient
    
    public enum Error: Swift.Error {
        case noConnectivity
        case invalidData
    }
    
    public init(url: URL, client: HTTPClient) {
        self.url = url
        self.client = client
    }
    
    public func load(completion: @escaping (Error) -> ()) {
        client.getDataFrom(url: url) { _ in
            completion(.noConnectivity)
        }
    }
}
