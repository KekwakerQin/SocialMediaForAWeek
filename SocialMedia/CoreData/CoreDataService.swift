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
        
        do {
            let results = try context.fetch(request)
            if let existing = results.first {
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
            
            try context.save()
        } catch {
            print("Failed to save like status: \(error)")
        }
    }
    
    func findPost(by id: Int) -> PostWithUser? {
        let request: NSFetchRequest<PostEntity> = PostEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %d", id)
        request.fetchLimit = 1
        
        do {
            let result = try context.fetch(request)
            if let entity = result.first {
                return PostWithUser(
                    id: Int(entity.id),
                    title: entity.title ?? "",
                    body: entity.body ?? "",
                    userName: entity.username ?? "",
                    avatarURL: URL(string: entity.avatarURL ?? "") ?? URL(string: "https://i.pravatar.cc/150")!,
                    isLiked: entity.isLiked
                )
            }
        } catch {
            print("Failed to find post: \(error)")
        }
        
        return nil
    }
    
    func saveAllPosts(_ posts: [PostWithUser]) {
        for post in posts {
            let request: NSFetchRequest<PostEntity> = PostEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %d", post.id)
            
            do {
                let result = try context.fetch(request)
                if let existing = result.first {
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
            } catch {
                print("Failed to fetch or save post \(post.id): \(error)")
            }
        }
        
        do {
            try context.save()
        } catch {
            print("Failed to save context: \(error)")
        }
    }
    
    func loadPosts() -> [PostWithUser] {
        let request: NSFetchRequest<PostEntity> = PostEntity.fetchRequest()
        
        do {
            let result = try context.fetch(request)
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
        } catch {
            print("Failed to load posts: \(error)")
            return []
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
