//
//  ViewController.swift
//  Combine-MVVM-DEMO
//
//  Created by Gucci on 8/18/24.
//

import Combine
import SnapKit
import Then
import UIKit

protocol QuoteFetchable {
    func fetchRandomQuote() -> AnyPublisher<Quote, Error>
}

final class QuoteService: QuoteFetchable {
    func fetchRandomQuote() -> AnyPublisher<Quote, any Error> {
        let url = URL(string: "https://api.quotable.io/random")!
        return URLSession.shared.dataTaskPublisher(for: url)
            .catch { error in
                return Fail(error: error).eraseToAnyPublisher()
            }
            .map { $0.data }
            .decode(type: Quote.self, decoder: JSONDecoder())
            .eraseToAnyPublisher()
    }
}

final class QuoteViewModel {
    private let service: QuoteFetchable

    init(service: QuoteFetchable = QuoteService()) {
        self.service = service
    }

    enum Input {
        case viewDidAppear
        case refreshButtonDidTap
    }

    enum Output {
        case fetchQuoteDidSucceed(quote: Quote)
        case fetchQuoteDidFailed(error: Error)
        case toggleButton(isEnable: Bool)
    }

    private let output = PassthroughSubject<Output, Never>()
    private var bag = Set<AnyCancellable>()

    func transform(input: AnyPublisher<Input, Never>) -> AnyPublisher<Output, Never> {
        input.sink { [weak self] event in
            switch event {
            case .refreshButtonDidTap, .viewDidAppear:
                self?.handleFetchRandomQuote()
            }
        }.store(in: &bag)

        return output.eraseToAnyPublisher()
    }

    private func handleFetchRandomQuote() {
        output.send(.toggleButton(isEnable: false))

        service.fetchRandomQuote().sink { [weak self] completion in
            self?.output.send(.toggleButton(isEnable: true))
            if case .failure(let error) = completion {
                self?.output.send(.fetchQuoteDidFailed(error: error))
            }
        } receiveValue: { [weak self] quote in
            self?.output.send(.fetchQuoteDidSucceed(quote: quote))
        }.store(in: &bag)
    }
}

final class QuoteViewController: UIViewController {
    private let quoteLabel = UILabel().then {
        $0.text = "Quote"
        $0.numberOfLines = 0
    }

    private lazy var refreshButton = UIButton().then {
        $0.setTitle("refresh", for: .normal)
        $0.setTitleColor(.white, for: .normal)
        $0.backgroundColor = .tintColor
        $0.layer.cornerRadius = 16
        $0.addTarget(self, action: #selector(refreshButtonDidTap), for: .touchUpInside)
    }

    private let vm = QuoteViewModel()
    private let input = PassthroughSubject<QuoteViewModel.Input, Never>()
    private var bag = Set<AnyCancellable>()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupLayout()
        setupBinding()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        input.send(.viewDidAppear)
    }

    private func setupLayout() {
        view.backgroundColor = .systemBackground

        [quoteLabel, refreshButton].forEach {
            self.view.addSubview($0)
        }

        quoteLabel.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview().inset(24)
            make.centerY.equalToSuperview()
        }

        refreshButton.snp.makeConstraints { make in
            make.top.equalTo(quoteLabel.snp.bottom).offset(8)
            make.horizontalEdges.equalToSuperview().inset(24)
        }
    }

    private func setupBinding() {
        let output = vm.transform(input: input.eraseToAnyPublisher())

        output
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                switch event {
                case .fetchQuoteDidSucceed(let quote):
                    self?.quoteLabel.text = quote.content
                case .fetchQuoteDidFailed(let error):
                    self?.quoteLabel.text = error.localizedDescription
                case .toggleButton(let isEnable):
                    self?.refreshButton.isEnabled = isEnable
                    self?.refreshButton.backgroundColor = isEnable ? .tintColor : .gray
                }
            }
            .store(in: &bag)
    }

    @objc
    private func refreshButtonDidTap() {
        input.send(.refreshButtonDidTap)
    }
}

struct Quote: Codable {
    let author: String
    let content: String
}
