import XCTest
@testable import SocialMedia

final class PostServiceTests: XCTestCase {
    
    func testFetchingPostsFromAPI() {
        // ожидание, чтобы тест подождал асинхронный запрос
        let expectation = self.expectation(description: "Fetching posts from API")
        
        PostService.shared.fetchPosts(limit: 10, offset: 0) { result in
            switch result {
            case .success(let posts):
                // Убедимся, что пришёл хотя бы 1 пост
                XCTAssertFalse(posts.isEmpty, "Посты не были загружены")
                print("✅ Получено постов: \(posts.count)")
                
            case .failure(let error):
                XCTFail("Ошибка загрузки постов: \(error)")
            }
            expectation.fulfill()
        }

        // Ждём максимум 5 секунд
        waitForExpectations(timeout: 5)
    }
}
