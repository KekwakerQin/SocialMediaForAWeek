import Foundation

final class PostViewModel {
    private(set) var posts: [PostWithUser] = []
    private var allPosts: [PostWithUser] = []
    
    private var currentPage = 0
    private let pageSize = 10
    private var isLoading = false
    
    var onPostsUpdated: (() -> Void)?
    
    func loadMockPosts() {
        allPosts = (1...50).map {
            PostWithUser(
                id: $0,
                title: "Заголовок \($0)",
                body: "Пост: \($0)",
                userName: "User \($0)",
                avatarURL: URL(string: "https://i.pravatar.cc/150?u=\($0)")!
            )
        }
        loadNextPage()
    }
    
    func loadNextPage() {
        guard !isLoading else { return }
        isLoading = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
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
        }
    }
}
