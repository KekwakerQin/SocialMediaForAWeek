// Модель поста
import Foundation

struct Post: Decodable {
    let id: Int
    let userId: Int
    let title: String
    let body: String
}
