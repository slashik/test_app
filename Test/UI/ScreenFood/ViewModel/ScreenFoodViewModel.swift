//
//  ScreenFoodViewModel.swift
//  Test
//
//  Created by Dmitry Yaskel on 21.03.2021.
//

import Foundation
import RxSwift
import RxCocoa

class ScreenFoodViewModel: ScreenFoodViewModelType {
    let startWeight: BehaviorRelay<WeightRepresentation?> = .init(value: nil)
    let targetWeight: BehaviorRelay<WeightRepresentation?> = .init(value: nil)
    let currentWeight: BehaviorRelay<WeightRepresentation?> = .init(value: nil)
    let activePeriod: BehaviorRelay<Period> = .init(value: .week)
    let chartData: BehaviorRelay<ChartView.ChartData?> = .init(value: nil)
    let chartPeriod: BehaviorRelay<(earliest: Date, latest: Date)?> = .init(value: nil)
    let changeStartWeight: PublishSubject<Weight?> = .init()
    let changeTargetWeight: PublishSubject<Weight?> = .init()
    let changeCurrentWeight: PublishSubject<Weight?> = .init()
    let error: PublishSubject<Error?> = .init()

    private let disposeBag = DisposeBag()
    private let dataSource: WeightDataSourceType
    private let dailyWeights: BehaviorRelay<[DailyWeight]> = .init(value: [])

    private var dateFormatter = DateFormatter()
    
    init(dataSource: WeightDataSourceType) {
        self.dataSource = dataSource
        
        NotificationCenter.default.rx
            .notification(NSLocale.currentLocaleDidChangeNotification)
            .subscribe(onNext: { [weak self] _ in
                self?.prepeareDataForView()
            })
            .disposed(by: disposeBag)
        
        bindings()
    }
}

private extension ScreenFoodViewModel {
    func bindings() {
        
        dataSource.error
            .bind(to: error)
            .disposed(by: disposeBag)
        
        dataSource.targetWeight
            .distinctUntilChanged()
            .map(weightToRepresentation)
            .bind(to: targetWeight)
            .disposed(by: disposeBag)
        
        dataSource.startWeight
            .distinctUntilChanged()
            .map(weightToRepresentation)
            .bind(to: startWeight)
            .disposed(by: disposeBag)
        
        dataSource.currentWeight
            .distinctUntilChanged()
            .map(weightToRepresentation)
            .bind(to: currentWeight)
            .disposed(by: disposeBag)
        
        changeStartWeight
            .bind(to: dataSource.changeStartWeight)
            .disposed(by: disposeBag)
        
        changeCurrentWeight
            .bind(to: dataSource.changeCurrentWeight)
            .disposed(by: disposeBag)
        
        changeTargetWeight
            .bind(to: dataSource.changeTargetWeight)
            .disposed(by: disposeBag)
        
        activePeriod
            .bind(to: dataSource.activePeriod)
            .disposed(by: disposeBag)
        
        dataSource.dailyWeights
            .bind(to: dailyWeights)
            .disposed(by: disposeBag)
        
        Observable
            .combineLatest(dailyWeights, currentWeight, targetWeight, startWeight)
            .bind(onNext: { [weak self] _ in
                self?.prepeareDataForView()
            })
            .disposed(by: disposeBag)
        
        dailyWeights
            .map({ weights -> (Date, Date)? in
                guard let oldest = weights.first, let earliest = weights.last else {
                    return nil
                }
                return (oldest.date, earliest.date)
            })
            .bind(to: chartPeriod)
            .disposed(by: disposeBag)
    }
}

private extension ScreenFoodViewModel {
    func weightToRepresentation(_ weight: Weight?) -> WeightRepresentation? {
        guard let weight = weight else {
            return nil
        }
        return WeightRepresentation(raw: weight)
    }
}

private extension ScreenFoodViewModel {
    func prepeareDataForView() {
        let weights = dailyWeights.value
        let sorted = weights.compactMap { $0.weight }.sorted(by: { $0 > $1})
      
        guard let targetWeight = targetWeight.value?.value, // :/
              var lowest = sorted.last,
              var highest = sorted.first else {
            fillEmptyData()
            return
        }
        if lowest > targetWeight {
            lowest = targetWeight
        } else if highest < targetWeight {
            highest = targetWeight
        }
        var diff = highest - lowest
        if diff == 0 {
            diff = highest * 0.3
        }
        let chartUnits = weights.map { dailyWeight -> ChartView.ChartUnit in
            let representation = WeightRepresentation(raw: dailyWeight.weight)
            let topTitle = representation.weight
            let topSubtitle = representation.measureValue
            switch activePeriod.value {
            case .week:
                dateFormatter.dateFormat = "dd"
            case .month:
                dateFormatter.dateFormat = "dd MMM"
            case .year:
                dateFormatter.dateFormat = "dd MMM"
            }
            let bottomTitle = dateFormatter.string(from: dailyWeight.date)
            
            let bottomSubtitle: String
            if NSCalendar.current.isDateInToday(dailyWeight.date) {
                bottomSubtitle = "TODAY"
            } else {
                if case .year = activePeriod.value {
                    dateFormatter.dateFormat = "YYYY"
                } else {
                    dateFormatter.dateFormat = "EEE"
                }
                bottomSubtitle = dateFormatter.string(from: dailyWeight.date)
            }
            var value: CGFloat?
            if let weight = dailyWeight.weight {
                value = CGFloat((weight - lowest) / diff)
            }
            return .init(title1: topTitle,
                         subtitle1: topSubtitle,
                         title2: bottomTitle,
                         subtitle2: bottomSubtitle,
                         value: value)
        }
        var chartLines = [ChartView.ChartLine]()
        let lowestWeight = Int(lowest)
        let highestWeight = Int(highest)
        let difference = highest - lowest
        for weight in lowestWeight...highestWeight {
            let divisionValue: Int
            switch difference {
            case 0...5:
                divisionValue = 1
            case 5...10:
                divisionValue = 2
            case 10...20:
                divisionValue = 3
            default:
                divisionValue = 10
            }
            guard weight%divisionValue == 0 else {
                continue
            }
            let unitValue = CGFloat((Weight(weight) - lowest) / diff)
            chartLines.append(.init(title: nil, subtitle: nil, value: unitValue))
        }
        
        let targetUnitValue = CGFloat((targetWeight - lowest) / diff)
        let chartData = ChartView.ChartData(chartUnits: chartUnits,
                                            chartLines: chartLines,
                                            target: .init(title: "Goal",
                                                          subtitle: WeightRepresentation(raw: targetWeight).weight,
                                                          value: targetUnitValue))
        self.chartData.accept(chartData)
    }
    
    func fillEmptyData() {
        let weights = dailyWeights.value
        
        let chartUnits = weights.map { dailyWeight -> ChartView.ChartUnit in
            let representation = WeightRepresentation(raw: dailyWeight.weight)
            let topTitle = representation.weight
            let topSubtitle = representation.measureValue
            switch activePeriod.value {
            case .week:
                dateFormatter.dateFormat = "dd"
            case .month:
                dateFormatter.dateFormat = "dd MMM"
            case .year:
                dateFormatter.dateFormat = "dd MMM"
            }
            let bottomTitle = dateFormatter.string(from: dailyWeight.date)
            
            let bottomSubtitle: String
            if NSCalendar.current.isDateInToday(dailyWeight.date) {
                bottomSubtitle = "TODAY"
            } else {
                if case .year = activePeriod.value {
                    dateFormatter.dateFormat = "YYYY"
                } else {
                    dateFormatter.dateFormat = "EEE"
                }
                bottomSubtitle = dateFormatter.string(from: dailyWeight.date)
            }
            return .init(title1: topTitle,
                         subtitle1: topSubtitle,
                         title2: bottomTitle,
                         subtitle2: bottomSubtitle,
                         value: nil)
        }
        let chartLines: [ChartView.ChartLine] = [
            .init(title: nil, subtitle: nil, value: 0.1),
            .init(title: nil, subtitle: nil, value: 0.4),
            .init(title: nil, subtitle: nil, value: 0.7),
            .init(title: nil, subtitle: nil, value: 1)
        ]
        
        let targetWeight = self.targetWeight.value ?? .init(raw: 0)
        
        let chartData = ChartView.ChartData(chartUnits: chartUnits,
                                            chartLines: chartLines,
                                            target: .init(title: "Goal",
                                                          subtitle: targetWeight.weight,
                                                          value: 0.2))
        self.chartData.accept(chartData)
        
    }
}

