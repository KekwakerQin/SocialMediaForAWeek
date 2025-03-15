import UIKit

func vibrateErrorIfNeeded() {
    // Статическая переменная хранит время последнего вызова
    struct Static {
        static var lastTime: Date = .distantPast
    }

    let now = Date()
    let delay: TimeInterval = 1

    // Если с последнего вызова прошло меньше delay — выходим
    guard now.timeIntervalSince(Static.lastTime) >= delay else { return }

    Static.lastTime = now

    let generator = UINotificationFeedbackGenerator()
    generator.prepare()
    generator.notificationOccurred(.error)
}
