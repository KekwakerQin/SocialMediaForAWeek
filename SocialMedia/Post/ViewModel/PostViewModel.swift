import Foundation

final class PostViewModel {
    private(set) var posts: [PostWithUser] = []
        
    internal(set) var currentPage = 0
    let pageSize = 10
    var isLoading = false
    var hasMoreData = true
    var allPosts: [PostWithUser] = []
    
    private var nextAPIPage = 0
    private let apiPageSize = 50 // сколько загружаем из API
        
    var onPostsUpdated: (() -> Void)?
    
//Это были моковые данные, чисто для теста оставил
    
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
        let savedPosts = CoreDataService.shared.loadPosts()

        if !savedPosts.isEmpty {
            let sorted = savedPosts.sorted { $0.isLiked && !$1.isLiked }

            self.posts = sorted
            self.allPosts = sorted
            self.currentPage = posts.count / pageSize
            self.hasMoreData = true
            self.onPostsUpdated?()
            
        }
        else {
            fetchMoreFromAPI()
        }
    }
    
    // подтягиваем данные
    func fetchPosts(limit: Int, offset: Int, completion: @escaping (Result<[PostWithUser], Error>) -> Void) {
        let postsURL = "https://jsonplaceholder.typicode.com/posts?_start=\(offset)&_limit=\(limit)"
        let usersURL = "https://jsonplaceholder.typicode.com/users"
    }
    
    // подгружаем больше данных limit - сколько постов загрузить в массив, offset - откуда начинать. И так иттерациями мы грузим по 50 постов, дабы разгрузиться
    func fetchMoreFromAPI() {
        guard hasMoreData else { return }

        isLoading = true

        PostService.shared.fetchPosts(limit: pageSize, offset: allPosts.count) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(var freshPosts):

                // 🔁 Восстанавливаем лайки из базы
                for i in 0..<freshPosts.count {
                    if let cached = CoreDataService.shared.findPost(by: freshPosts[i].id) {
                        freshPosts[i].isLiked = cached.isLiked
                    }
                }

                if freshPosts.isEmpty {
                    self.hasMoreData = false
                    self.isLoading = false
                    return
                }

                self.allPosts.append(contentsOf: freshPosts)

                // Только часть отображаем сразу
                let neededEnd = min((self.currentPage + 1) * self.pageSize, self.allPosts.count)
                let newVisible = self.allPosts[self.posts.count..<neededEnd]
                self.posts.append(contentsOf: newVisible)

                self.currentPage += 1
                self.isLoading = false

                CoreDataService.shared.saveAllPosts(freshPosts)
                self.onPostsUpdated?()

            case .failure(let error):
                print("Ошибка загрузки: \(error)")
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
    
    // Подгружаем данные в UI
    func loadNextPage() {
        guard !isLoading else { return } // Пока идет загрузка, не запускать, иначе появятся дубликаты
        isLoading = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in // имитирую что данные просто быстро грузятся, а не моментально, что невозможно
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
            CoreDataService.shared.saveAllPosts(self.posts)
            
            let remaining = self.allPosts.count - (self.currentPage * self.pageSize) // если осталось 10 и меньше, то мы подгружаем еще одну порцию данных в массив (50 шт)
            if remaining <= self.pageSize && self.hasMoreData {
                self.fetchMoreFromAPI()
            }
        }
    }
    
    func toggleLike(for post: PostWithUser) {
        guard let index = posts.firstIndex(where: { $0.id == post.id }) else { return }
        
        posts[index].isLiked.toggle()
        
        if let allIndex = allPosts.firstIndex(where: { $0.id == post.id }) {
            allPosts[allIndex].isLiked = posts[index].isLiked
        }

        CoreDataService.shared.saveLikeStatus(for: posts[index])

        posts.sort { $0.isLiked && !$1.isLiked }

        onPostsUpdated?()
    }
    
    func clearAllData() {
        CoreDataService.shared.clearAllPosts()
        posts.removeAll()
        allPosts.removeAll()
        currentPage = 0
        nextAPIPage = 0
        hasMoreData = true
        isLoading = false
    }
    
}
