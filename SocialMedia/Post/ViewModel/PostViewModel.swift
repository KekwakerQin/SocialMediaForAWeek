import Foundation

final class PostViewModel {
    private(set) var posts: [PostWithUser] = []
    private var allPosts: [PostWithUser] = []
    
    private var currentPage = 0
    private let pageSize = 10
    private var isLoading = false
    
    private var nextAPIPage = 0
    private let apiPageSize = 50 // сколько загружаем из API
    
    private var hasMoreData = true
    
    var onPostsUpdated: (() -> Void)?
    
//    func loadMockPosts() {
//        allPosts = (1...30).map {
//            PostWithUser(
//                id: $0,
//                title: "Заголовок \($0)",
//                body: "Пост: \($0)",
//                userName: "User \($0)",
//                avatarURL: URL(string: "https://i.pravatar.cc/150?u=\($0)")!
//            )
//        }
//        loadNextPage()
//    }
    
    func loadInitialPosts() {
        fetchMoreFromAPI()
    }
    
    func fetchPosts(limit: Int, offset: Int, completion: @escaping (Result<[PostWithUser], Error>) -> Void) {
        let postsURL = "https://jsonplaceholder.typicode.com/posts?_start=\(offset)&_limit=\(limit)"
        let usersURL = "https://jsonplaceholder.typicode.com/users"
    }
    
    private func fetchMoreFromAPI() {
        guard hasMoreData else { return }

        isLoading = true
        
        PostService.shared.fetchPosts(limit: apiPageSize, offset: nextAPIPage * apiPageSize) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let newPosts):
                if newPosts.isEmpty {
                    self.hasMoreData = false
                    self.isLoading = false
                    return
                }

                self.allPosts.append(contentsOf: newPosts)
                self.nextAPIPage += 1
                self.isLoading = false

                self.loadNextPage()
            case .failure(let error):
                print("Ошибка дозагрузки:", error)
                self.isLoading = false
            }
        }
    }
    
    func loadFromAPI() {
        PostService.shared.fetchPosts(limit: 50, offset: 0) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let posts):
                self.allPosts = posts
                self.nextAPIPage = 1 
                self.loadNextPage()
            case .failure(let error):
                print("API Error:", error)
            }
        }
    }
    
    func loadNextPage() {
        guard !isLoading else { return }
        isLoading = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }

            let start = self.currentPage * self.pageSize
            let end = min(start + self.pageSize, self.allPosts.count)
            guard start < end else {
                self.isLoading = false
                return
            }

            let newPosts = self.allPosts[start..<end]
            self.posts.append(contentsOf: newPosts)
            self.currentPage += 1
            self.isLoading = false

            self.onPostsUpdated?()
            
            let remaining = self.allPosts.count - (self.currentPage * self.pageSize)
            if remaining <= self.pageSize && self.hasMoreData {
                self.fetchMoreFromAPI()
            }
        }
        
        
    }
    
    
}
