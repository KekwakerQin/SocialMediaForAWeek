import Foundation

struct User: Decodable {
    let id: Int
    let name: String
    var avatarURL: URL {
        return URL(string: "https://i.pravatar.cc/150?u=\(id)")! // (монолог) долго выяснял в чем ошибка, почему в мок данных все норм, а при подтягивании из JSON не прогружает постов, оказалось что я просто не заметил что в JSON-е нет аватарки
    }
}
