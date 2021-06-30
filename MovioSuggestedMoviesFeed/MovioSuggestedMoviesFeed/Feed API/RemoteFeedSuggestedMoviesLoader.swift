import Foundation

public protocol HTTPClient {
    func getDataFrom(url: URL)
}

public final class RemoteFeedSuggestedMoviesLoader {
    private let url: URL
    private let client: HTTPClient
    
    public init(url: URL, client: HTTPClient) {
        self.url = url
        self.client = client
    }
    
    public func load() {
        client.getDataFrom(url: url)
    }
}
