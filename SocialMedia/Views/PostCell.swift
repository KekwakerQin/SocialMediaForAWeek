import UIKit

final class PostCell: UITableViewCell {
    static let reuseId = "PostCell"
    
    private let avatarImageView = UIImageView()
    
    private let titleLabel = UILabel()
    private let bodyLabel = UILabel()
    private let likeButton = UIButton(type: .system)
    
    var onLikeTapped: (() -> Void)?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    

    // ячейка для модели
    func configure(with post: PostWithUser) {
        titleLabel.text = post.title
        bodyLabel.text = post.body
        loadAvatar(url: post.avatarURL)
        
        let heart = post.isLiked ? "♥︎" : "♡"
        likeButton.setTitle(heart, for: .normal)
        likeButton.tintColor = post.isLiked ? .systemRed : .lightGray
    }

    private func loadAvatar(url: URL) {
        // Апдейт. Возможно можно было бы добавить кэширование
        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let self = self, let data = data, error == nil else { return }
            DispatchQueue.main.async {
                self.avatarImageView.image = UIImage(data: data)
            }
        }.resume()
    }
    
    // Настройка UI
    private func setupUI() {
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.clipsToBounds = true
        avatarImageView.layer.cornerRadius = 25

        titleLabel.font = UIFont.preferredFont(forTextStyle: .headline)
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.numberOfLines = 2
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.8

        bodyLabel.font = UIFont.preferredFont(forTextStyle: .subheadline)
        bodyLabel.adjustsFontForContentSizeCategory = true
        bodyLabel.numberOfLines = 3
        bodyLabel.lineBreakMode = .byTruncatingTail
        bodyLabel.adjustsFontSizeToFitWidth = true
        bodyLabel.minimumScaleFactor = 0.8
        bodyLabel.textColor = .gray

        likeButton.setTitle("♡", for: .normal)
        likeButton.titleLabel?.font = UIFont.systemFont(ofSize: 20)
        likeButton.setContentHuggingPriority(.required, for: .horizontal)
        likeButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        likeButton.addTarget(self, action: #selector(didTapLike), for: .touchUpInside)
        likeButton.translatesAutoresizingMaskIntoConstraints = false
        likeButton.widthAnchor.constraint(equalToConstant: 40).isActive = true // фикс ширина

        let textStack = UIStackView(arrangedSubviews: [titleLabel, bodyLabel])
        textStack.axis = .vertical
        textStack.spacing = 8
        textStack.translatesAutoresizingMaskIntoConstraints = false
        textStack.heightAnchor.constraint(lessThanOrEqualToConstant: 80).isActive = true

        let horizontalStack = UIStackView(arrangedSubviews: [avatarImageView, textStack, likeButton])
        horizontalStack.axis = .horizontal
        horizontalStack.spacing = 12
        horizontalStack.alignment = .center
        horizontalStack.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(horizontalStack)

        NSLayoutConstraint.activate([
            avatarImageView.widthAnchor.constraint(equalToConstant: 50),
            avatarImageView.heightAnchor.constraint(equalToConstant: 50),

            horizontalStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            horizontalStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
            horizontalStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            horizontalStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
        ])
    }

    @objc private func didTapLike() {
        onLikeTapped?()
    }
    
}

#if DEBUG
import SwiftUI

struct PostCell_Previews: PreviewProvider {
    static var previews: some View {
        UIViewPreview {
            let cell = PostCell(style: .default, reuseIdentifier: nil)
            // Передаем данные для предпросмотра
            let dummyPost = PostWithUser(
                id: 1,
                title: "Title",
                body: "Body place of text many textBody place of text many textBody place of text many textBody place of text many textBody place of text many textBody place of text many textBody place of text many textBody place of text many textBody place of tet many textBody place of text many textBody place of text many textBody place of text many textBody place of text many textBody place of t",
                userName: "Test User",
                avatarURL: URL(string: "https://i.pravatar.cc/150?u=1")!
            )
            cell.configure(with: dummyPost)
            return cell
        }
        .previewLayout(.fixed(width: 375, height: 100))
    }
}

// отображение в Canvas
struct UIViewPreview<View: UIView>: UIViewRepresentable {
    let viewBuilder: () -> View

    init(_ builder: @escaping () -> View) {
        self.viewBuilder = builder
    }

    func makeUIView(context: Context) -> View {
        viewBuilder()
    }

    func updateUIView(_ uiView: View, context: Context) {}
}
#endif
