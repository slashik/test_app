//
//  ScreenFoodViewController.swift
//  Test
//
//  Created by Dmitry Yaskel on 20.03.2021.
//

import UIKit
import RxSwift
import RxCocoa

class ScreenFoodViewController: UIViewController {
    @IBOutlet private weak var startWeightView: WeightView!
    @IBOutlet private weak var targetWeightView: WeightView!
    @IBOutlet private weak var currentWeightView: WeightView!
    @IBOutlet private weak var chartView: ChartView!
    @IBOutlet private weak var periodLabel: UILabel!
    @IBOutlet private weak var segmentedControl: AmazingSegmentedControl!
    
    private let viewModel: ScreenFoodViewModelType
    private let disposeBag = DisposeBag()

    private var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM, YYYY"
        return formatter
    }()
    
    init(viewModel: ScreenFoodViewModelType) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureUiElements()
        bindings()
    }
}

private extension ScreenFoodViewController {
    func configureUiElements() {
        startWeightView.configuration.onNext(.header)
        targetWeightView.configuration.onNext(.sub)
        currentWeightView.configuration.onNext(.sub)
        
        let backButton = UIBarButtonItem(image: UIImage(named: "Left"), style: .done, target: self, action: #selector(backPressed(_:)))
        backButton.tintColor = .black
        navigationItem.leftBarButtonItem = backButton
    }
}

private extension ScreenFoodViewController {
    func bindings() {
        bindWeightRelay(viewModel.startWeight, subtitle: "Start Weight", to: startWeightView)
        bindWeightRelay(viewModel.targetWeight, subtitle: "Target Weight", to: targetWeightView)
        bindWeightRelay(viewModel.currentWeight, subtitle: "Current Weight", to: currentWeightView)
        
        bindView(targetWeightView, current: viewModel.targetWeight, to: viewModel.changeTargetWeight)
        bindView(currentWeightView, current: viewModel.currentWeight, to: viewModel.changeCurrentWeight)
        bindView(startWeightView, current: viewModel.startWeight, to: viewModel.changeStartWeight)

        viewModel.chartPeriod
            .map(periodText)
            .bind(to: periodLabel.rx.text)
            .disposed(by: disposeBag)
        
        viewModel.chartData
            .observe(on: MainScheduler.instance)
            .map(prepeareDataToView)
            .bind(to: chartView.chartData)
            .disposed(by: disposeBag)
        
        viewModel.error
            .observe(on: MainScheduler.instance)
            .compactMap { $0 }
            .bind { [weak self] error in
                let alertController = UIAlertController(title: nil, message: error.localizedDescription, preferredStyle: .alert)
                alertController.addAction(.init(title: "OK", style: .default, handler: nil))
                self?.present(alertController, animated: true, completion: nil)
        }
            .disposed(by: disposeBag)
                
        segmentedControl.selectedIndex
            .bind { [weak self] index in
                switch index {
                case 0:
                    self?.viewModel.activePeriod.accept(.week)
                case 1:
                    self?.viewModel.activePeriod.accept(.month)
                default:
                    self?.viewModel.activePeriod.accept(.year)
                }
            }
            .disposed(by: disposeBag)
    }
    
    func bindView(_ view: WeightView, current: BehaviorRelay<WeightRepresentation?>, to relay: PublishSubject<Weight?>) {
        view.buttonSubject
            .bind { [weak self] _ in
                guard let disposeBag = self?.disposeBag else {
                    return
                }
                let alertController = UIAlertController(title: "Enter weight", message: nil, preferredStyle: .alert)
                alertController.addTextField { textField in
                    textField.enablesReturnKeyAutomatically = true
                    if let startWeight = current.value?.value {
                        textField.text = "\(startWeight)"
                    }
                    textField.placeholder = "..."
                    textField.keyboardType = .decimalPad
                    textField.rx
                        .controlEvent(.editingDidEnd)
                        .bind { _ in
                            if let text = textField.text?.replacingOccurrences(of: ",", with: "."), !text.isEmpty {
                                relay.onNext(Double(text))
                            }
                        }
                        .disposed(by: disposeBag)
                }
                alertController.addAction(.init(title: "OK", style: .default, handler: nil))
                self?.present(alertController, animated: true, completion: nil)
            }
            .disposed(by: disposeBag)
    }
    
    func bindWeightRelay(_ weightRelay: BehaviorRelay<WeightRepresentation?>, subtitle: String, to weightView: WeightView) {
        weightRelay
            .map({ representation -> String in
                guard let representation = representation else {
                    return "-"
                }
                return "\(representation.weight) \(representation.measureValue)"
            })
            .map { WeightView.ViewData(title: $0, subtitle: subtitle) }
            .bind(to: weightView.viewData)
            .disposed(by: disposeBag)
    }
    
    func periodText(period: (earliest: Date, latest: Date)?) -> String {
        guard let period = period else {
            return ""
        }
        return "\(dateFormatter.string(from: period.earliest)) - \(dateFormatter.string(from: period.latest))".uppercased()
    }
    
    func prepeareDataToView(_ data: ChartView.ChartData?) -> ChartView.ChartData? {
        guard let chartData = data else {
            return data
        }
        let overallCount = 7
        let distance = chartData.chartUnits.count/overallCount
        var emptyDatesCount = 0
        let chartUnits: [ChartView.ChartUnit] = chartData.chartUnits.reversed().enumerated().reduce(into: [ChartView.ChartUnit]()) { result, unit in
            switch viewModel.activePeriod.value {
            case .week:
                result.append(unit.element)
            case .month,
                 .year:
                let distanceTrigger = unit.element.value != nil && emptyDatesCount >= distance
                let isFirstUnit = unit.offset == 0
                let lastUnitIndex = chartData.chartUnits.count - 1
                let isLastUnit = unit.offset == lastUnitIndex
                let isNonNearLastUnit = unit.offset < lastUnitIndex - distance
                if (distanceTrigger && isNonNearLastUnit)
                    || isFirstUnit
                    || isLastUnit {
                    result.append(unit.element)
                    emptyDatesCount = 0
                } else {
                    result.append(.empty(with: unit.element.value))
                    emptyDatesCount += 1
                }
            }
        }.reversed()

        return .init(chartUnits: chartUnits,
                     chartLines: chartData.chartLines,
                     target: chartData.target)
    }
}

private extension ScreenFoodViewController {
    @IBAction func backPressed(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
}

private extension ChartView.ChartUnit {
    static func empty(with value: CGFloat?) -> ChartView.ChartUnit {
        return .init(title1: nil,
                     subtitle1: nil,
                     title2: nil,
                     subtitle2: nil,
                     value: value)
    }
}
