//
//  AmazingSegmentedControl.swift
//  Test
//
//  Created by Dmitry Yaskel on 21.03.2021.
//

import UIKit
import RxSwift
import RxCocoa

class AmazingSegmentedControl: UIView {
    let selectedIndex: BehaviorRelay<Int> = .init(value: 0)
    private let disposeBag = DisposeBag()
    
    private let stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [])
        stackView.alignment = .fill
        stackView.distribution = .fillEqually
        stackView.spacing = 13
        stackView.axis = .horizontal
        
        return stackView
    }()
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        addSubview(stackView)
        stackView.frame = bounds
        stackView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        ["Week", "Month", "Year"].enumerated().forEach { index, text in
            let button = UIButton(type: .custom)
            stackView.addArrangedSubview(button)
            button.titleLabel?.font = UIFont(name: "OpenSans-Light", size: 11)
            button.setTitle(text, for: .normal)
            button.tag = index
            button.addTarget(self, action: #selector(buttonPressed(_:)), for: .touchUpInside)
        }
        selectedIndex
            .observe(on: MainScheduler.instance)
            .bind { [weak self] _ in
                self?.configureButtons()
            }
            .disposed(by: disposeBag)
    }
}

private extension AmazingSegmentedControl {
    func configureButtons() {
        (stackView.arrangedSubviews as? [UIButton])?.enumerated().forEach { index, button in
            button.layer.cornerRadius = bounds.height/2
            button.setTitleColor(.black, for: .normal)
            button.clipsToBounds = true
            if index == selectedIndex.value {
                button.layer.borderWidth = 0.0
                button.backgroundColor = #colorLiteral(red: 0.8823529412, green: 0.8823529412, blue: 0.9294117647, alpha: 0.43)
            } else {
                button.layer.borderWidth = 0.2
                button.backgroundColor = .clear
            }
        }
    }
    
    @objc func buttonPressed(_ sender: UIButton) {
        selectedIndex.accept(sender.tag)
    }
}
