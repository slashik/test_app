//
//  TransparentBarNavigationController.swift
//  Test
//
//  Created by Dmitry Yaskel on 28.03.2021.
//

import UIKit

class TransparentBarNavigationController: UINavigationController {

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        navigationBar.shadowImage = UIImage()
        navigationBar.isTranslucent = true
        view.backgroundColor = UIColor.clear
    }
}
