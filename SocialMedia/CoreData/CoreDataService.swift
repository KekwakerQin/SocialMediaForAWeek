import Foundation
import CoreData
import UIKit

final class CoreDataService {
    static let shared = CoreDataService()
    
    private init() {}
    
    lazy var permanentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "SocialMedia")
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Storage load error: \(error)")
            }
        }
        return container
    }()
    
    var context: NSManagedObjectContext {
        permanentContainer.viewContext
    }
    
    func saveLikeStatus(for post: PostWithUser) {
            let request: NSFetchRequest<PostEntity> = PostEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %d", post.id)

            if let results = try? context.fetch(request), let existing = results.first {
                existing.isLiked = post.isLiked
            } else {
                let entity = PostEntity(context: context)
                entity.id = Int64(post.id)
                entity.title = post.title
                entity.body = post.body
                entity.username = post.userName
                entity.avatarURL = post.avatarURL.absoluteString
                entity.isLiked = post.isLiked
            }

            try? context.save()
        }
    
    func findPost(by id: Int) -> PostWithUser? {
        let request: NSFetchRequest<PostEntity> = PostEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %d", id)
        request.fetchLimit = 1

        if let result = try? context.fetch(request), let entity = result.first {
            return PostWithUser(
                id: Int(entity.id),
                title: entity.title ?? "",
                body: entity.body ?? "",
                userName: entity.username ?? "",
                avatarURL: URL(string: entity.avatarURL ?? "") ?? URL(string: "https://i.pravatar.cc/150")!,
                isLiked: entity.isLiked
            )
        }

        return nil
    }
    
    func saveAllPosts(_ posts: [PostWithUser]) {
        for post in posts {
            let request: NSFetchRequest<PostEntity> = PostEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %d", post.id)

            if let result = try? context.fetch(request), let existing = result.first {
                existing.title = post.title
                existing.body = post.body
                existing.username = post.userName
                existing.avatarURL = post.avatarURL.absoluteString
                existing.isLiked = post.isLiked
            } else {
                let entity = PostEntity(context: context)
                entity.id = Int64(post.id)
                entity.title = post.title
                entity.body = post.body
                entity.username = post.userName
                entity.avatarURL = post.avatarURL.absoluteString
                entity.isLiked = post.isLiked
            }
        }

        try? context.save()
    }

    func loadPosts() -> [PostWithUser] {
        let request: NSFetchRequest<PostEntity> = PostEntity.fetchRequest()
        
        guard let result = try? context.fetch(request) else {
            return []
        }
        
        return result.map {
            PostWithUser(
                id: Int($0.id),
                title: $0.title ?? "",
                body: $0.body ?? "",
                userName: $0.username ?? "",
                avatarURL: URL(string: $0.avatarURL ?? "") ?? URL(string: "https://i.pravatar.cc/150")!,
                isLiked: $0.isLiked
            )
        }
    }
    
    func clearAllPosts() {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = PostEntity.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

        do {
            try context.execute(deleteRequest)
            try context.save()
        } catch {
            print("Ошибка при удалении кэша: \(error)")
        }
    }
}
