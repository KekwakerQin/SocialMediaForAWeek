import Foundation

final class PostViewModel {
    private(set) var posts: [PostWithUser] = [] // Показанные в таблице
    private(set) var allPosts: [PostWithUser] = []  // Все загруженные (локально + из сети)
    
    private(set) var currentPage = 0    // Номер "порции" (каждая по pageSize)
    let pageSize = 10
    
    var isLoading = false {
        didSet {
            onLoadingStateChanged?(isLoading)
        }
    }
    var hasMoreData = true
    
    // Коллбеки для ViewController
    var onPostsUpdated: (() -> Void)?
    var onLoadingStateChanged: ((Bool) -> Void)?
    
    func loadLocalPostsIfAny() {
        let savedPosts = CoreDataService.shared.loadPosts()
        if !savedPosts.isEmpty {
            // например, сортируем лайкнутые вверх
            let sorted = savedPosts.sorted { $0.isLiked && !$1.isLiked }
            allPosts = sorted
        }
    }
    
    func loadNextPage() {
        guard hasMoreData else { return }
        guard !isLoading else { return }
        
        isLoading = true

        let nextPageStart = currentPage * pageSize
        let nextPageEnd = nextPageStart + pageSize
        
        // Если уже в памяти (allPosts) лежит достаточно постов, берём оттуда
        if allPosts.count >= nextPageEnd {
            // Эмулируем "задержку 1 секунду"
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                self?.appendNextChunkFromLocal()
            }
        } else {
            // Иначе нужно подгрузить ещё с API
            fetchMoreFromAPI { [weak self] success in
                guard let self = self else { return }
                
                // Если API не смог ничего дать, дальше не идём
                if !success {
                    self.isLoading = false
                    return
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.appendNextChunkFromLocal()
                }
            }
        }
    }
    
    private func appendNextChunkFromLocal() {
        let start = currentPage * pageSize
        let end = min(start + pageSize, allPosts.count)
        
        guard start < end else {
            // Значит, может быть не осталось постов или они не пришли
            isLoading = false
            hasMoreData = false
            onPostsUpdated?()
            return
        }
        
        let newPosts = allPosts[start..<end]
        posts.append(contentsOf: newPosts)
        currentPage += 1
        
        // Сохраняем в CoreData
        CoreDataService.shared.saveAllPosts(posts)
        
        // Проверяем, не иссякли ли данные (если API вернул меньше 10, значит больше ничего нет)
        if allPosts.count < currentPage * pageSize {
            hasMoreData = false
        }
        
        isLoading = false
        onPostsUpdated?()
    }
    
    func fetchMoreFromAPI(completion: @escaping (Bool) -> Void) {
        let offset = allPosts.count // продолжаем с того места, где закончились
        PostService.shared.fetchPosts(limit: pageSize, offset: offset) { result in
            switch result {
            case .success(var freshPosts):
                // Сверим статус лайка с кэшем
                for i in 0..<freshPosts.count {
                    if let cached = CoreDataService.shared.findPost(by: freshPosts[i].id) {
                        freshPosts[i].isLiked = cached.isLiked
                    }
                }
                
                if freshPosts.isEmpty {
                    self.hasMoreData = false
                    completion(false)
                    return
                }

                // Добавляем их в allPosts
                self.allPosts.append(contentsOf: freshPosts)
                
                // Сохраняем только свежие посты
                CoreDataService.shared.saveAllPosts(freshPosts)
                
                completion(true)
                
            case .failure(let error):
                print("Ошибка загрузки с API: \(error)")
                completion(false)
            }
        }
    }

    // MARK: - Лайки
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

    // MARK: - Очистка
    func clearAllData() {
        CoreDataService.shared.clearAllPosts()
        posts.removeAll()
        allPosts.removeAll()
        currentPage = 0
        hasMoreData = true
        isLoading = false
    }
}
