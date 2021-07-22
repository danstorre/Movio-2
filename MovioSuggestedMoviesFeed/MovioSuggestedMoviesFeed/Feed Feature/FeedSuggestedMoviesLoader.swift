
import Foundation

public enum FeedSuggestedMoviesLoaderResult<Error: Swift.Error> {
    case success([FeedSuggestedMovie])
    case failure(Error)
}

protocol FeedSuggestedMoviesLoader {
    associatedtype T: Swift.Error
    func load(completion: @escaping (FeedSuggestedMoviesLoaderResult<T>) -> Void)
}
