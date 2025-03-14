import Foundation
import Alamofire

final class PostService {
    static let shared = PostService()
    
    private init() {}
    
    func fetchPosts(limit: Int, offset: Int, completion: @escaping (Result<[PostWithUser], Error>) -> Void) {
        let postsURL = "https://jsonplaceholder.typicode.com/posts?_start=\(offset)&_limit=\(limit)"
        let usersURL = "https://jsonplaceholder.typicode.com/users"
        
        let group = DispatchGroup()
        var fetchedPosts: [Post] = []
        var fetchedUsers: [User] = []
        var firstError: Error?
        
        // Fetch Posts
        group.enter()
        AF.request(postsURL)
            .validate()
            .responseDecodable(of: [Post].self) { response in
                switch response.result {
                case .success(let posts):
                    fetchedPosts = posts
                case .failure(let error):
                    if firstError == nil { firstError = error }
                }
                group.leave()
            }
        
        // Fetch Users
        group.enter()
        AF.request(usersURL)
            .validate()
            .responseDecodable(of: [User].self) { response in
                switch response.result {
                case .success(let users):
                    fetchedUsers = users
                case .failure(let error):
                    if firstError == nil { firstError = error }
                }
                group.leave()
            }
        
        // Combine and Return
        group.notify(queue: .main) {
            if let error = firstError {
                completion(.failure(error))
                return
            }
            
            let postsWithUsers: [PostWithUser] = fetchedPosts.compactMap { post in
                guard let user = fetchedUsers.first(where: { $0.id == post.userId }) else {
                    return nil
                }
                return PostWithUser(
                    id: post.id,
                    title: post.title,
                    body: post.body,
                    userName: user.name,
                    avatarURL: user.avatarURL
                )
            }
            
            completion(.success(postsWithUsers))
        }
    }
}
