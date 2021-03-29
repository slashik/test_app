//
//  WeightView.swift
//  Test
//
//  Created by Dmitry Yaskel on 20.03.2021.
//

import UIKit
import Reusable
import RxSwift

class WeightView: UIView, NibOwnerLoadable {
    struct ViewData {
        let title: String
        let subtitle: String
    }
    enum Configuration {
        case header
        case sub
    }
    
    let viewData: PublishSubject<ViewData> = .init()
    let configuration: PublishSubject<Configuration> = .init()
    let buttonSubject: PublishSubject<Void?> = .init()

    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var subtitleLabel: UILabel!
    @IBOutlet private weak var redoButton: UIButton!
    
    private let disposeBag = DisposeBag()
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        loadNibContent()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        bindings()
    }
}

private extension WeightView {
    func bindings() {
        configuration
            .observe(on: MainScheduler.instance)
            .subscribe { [weak self] configuration in
                self?.setup(configuration: configuration)
            }
            .disposed(by: disposeBag)

        
        viewData
            .observe(on: MainScheduler.instance)
            .subscribe { [weak self] data in
                self?.setup(viewData: data)
            }
            .disposed(by: disposeBag)
        
        redoButton.rx
            .controlEvent(.touchUpInside)
            .bind(to: buttonSubject)
            .disposed(by: disposeBag)
    }
    
    func setup(configuration: Configuration) {
        switch configuration {
        case .header:
            titleLabel.font = UIFont(name: "OpenSans-ExtraBold", size: 24)
            subtitleLabel.font = UIFont(name: "OpenSans-Light", size: 24)
            subtitleLabel.textColor = #colorLiteral(red: 0.6509803922, green: 0.6745098039, blue: 0.7450980392, alpha: 1)
        case .sub:
            titleLabel.font = UIFont(name: "OpenSans-Bold", size: 24)
            subtitleLabel.font = UIFont(name: "OpenSans-Light", size: 13)
            subtitleLabel.textColor = .black
        }
    }
    
    func setup(viewData: ViewData) {
        titleLabel.text = viewData.title
        subtitleLabel.text = viewData.subtitle
    }
}
