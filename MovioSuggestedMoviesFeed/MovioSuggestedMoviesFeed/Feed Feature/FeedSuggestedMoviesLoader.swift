
import Foundation

public enum FeedSuggestedMoviesLoaderResult<Error: Swift.Error> {
    case success([FeedSuggestedMovie])
    case failure(Error)
}

extension FeedSuggestedMoviesLoaderResult: Equatable where Error: Equatable {}

protocol FeedSuggestedMoviesLoader {
    associatedtype T: Swift.Error
    func load(completion: @escaping (FeedSuggestedMoviesLoaderResult<T>) -> Void)
}
