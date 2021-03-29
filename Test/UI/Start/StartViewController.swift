//
//  StartViewController.swift
//  Test
//
//  Created by Dmitry Yaskel on 28.03.2021.
//

import UIKit

class StartViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
    }
}

private extension StartViewController {
    @IBAction func healthKitPressed(_ sender: Any) {
        showFoodViewController(with: HealthKitDataSource())
    }
    
    @IBAction func randomPressed(_ sender: Any) {
        showFoodViewController(with: RandomWeightDataSource())
    }
    
    func showFoodViewController(with dataSource: WeightDataSourceType) {
        let viewModel = ScreenFoodViewModel(dataSource: dataSource)
        let viewController = ScreenFoodViewController(viewModel: viewModel)
        navigationController?.pushViewController(viewController, animated: true)
    }
}
