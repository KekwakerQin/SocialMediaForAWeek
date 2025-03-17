import UIKit

final class PostViewController: UIViewController {
    private let tableView = UITableView()
    private let viewModel = PostViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Очистить",
            style: .plain,
            target: self,
            action: #selector(clearCacheTapped)
        )
        
        setupTableView()
        bindViewModel()
        
        viewModel.loadLocalPostsIfAny()

        viewModel.loadNextPage()
    }
    
    private func bindViewModel() {
        viewModel.onPostsUpdated = { [weak self] in
            guard let self = self else { return }
            self.tableView.reloadData()
            self.hideLoadingFooter()
            self.title = "Posts (\(self.viewModel.posts.count))"
        }
        
        viewModel.onLoadingStateChanged = { [weak self] isLoading in
            if isLoading {
                self?.showLoadingFooter()
            } else {
                self?.hideLoadingFooter()
            }
        }
    }

    private func setupTableView() {
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(PostCell.self, forCellReuseIdentifier: PostCell.reuseId)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor)
        ])
    }
    
    private func showLoadingFooter() {
        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.startAnimating()
        spinner.frame = CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 44)
        tableView.tableFooterView = spinner
    }

    private func hideLoadingFooter() {
        tableView.tableFooterView = nil
    }
    
    @objc private func clearCacheTapped() {
        viewModel.clearAllData()
        
        // Обнулить UI
        tableView.reloadData()
        title = "Posts (0)"
        
        // Запускаем заново
        viewModel.loadNextPage()
    }
}

extension PostViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.posts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let post = viewModel.posts[indexPath.row]
        guard let cell = tableView.dequeueReusableCell(withIdentifier: PostCell.reuseId, for: indexPath) as? PostCell else {
            return UITableViewCell()
        }
        
        cell.configure(with: post)
        
        cell.onLikeTapped = { [weak self] in
            self?.viewModel.toggleLike(for: post)
        }
        return cell
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let frameHeight = scrollView.frame.size.height

        // Если пользователь почти у нижней границы, но данных больше нет — вибрация
        if offsetY > contentHeight - frameHeight * 0.9, !viewModel.hasMoreData {
            vibrateErrorIfNeeded()
            return
        }

        // Обычная подгрузка при прокрутке
        if offsetY > contentHeight - frameHeight * 1.5 {
            viewModel.loadNextPage()
        }
    }
}

#if DEBUG
import SwiftUI

struct PostViewController_Previews: PreviewProvider {
    static var previews: some View {
        ViewControllerPreview {
            UINavigationController(rootViewController: PostViewController())
        }
        .edgesIgnoringSafeArea(.all)
    }
}

struct ViewControllerPreview<ViewController: UIViewController>: UIViewControllerRepresentable {
    let viewControllerBuilder: () -> ViewController

    init(_ builder: @escaping () -> ViewController) {
        self.viewControllerBuilder = builder
    }

    func makeUIViewController(context: Context) -> ViewController {
        viewControllerBuilder()
    }

    func updateUIViewController(_ uiViewController: ViewController, context: Context) {}
}
#endif
