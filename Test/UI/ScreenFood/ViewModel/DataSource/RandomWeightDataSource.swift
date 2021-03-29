//
//  RandomWeightDataSource.swift
//  Test
//
//  Created by Dmitry Yaskel on 21.03.2021.
//

import Foundation
import RxSwift
import RxCocoa

class RandomWeightDataSource: WeightDataSourceType {
    let startWeight: BehaviorRelay<Weight?> = .init(value: 60.2)
    let targetWeight: BehaviorRelay<Weight?> = .init(value: nil)
    let currentWeight: BehaviorRelay<Weight?> = .init(value: nil)
    let dailyWeights: BehaviorRelay<[DailyWeight]> = .init(value: [])
    let activePeriod: BehaviorRelay<Period> = .init(value: .week)
    let changeStartWeight: PublishSubject<Weight?> = .init()
    let changeTargetWeight: PublishSubject<Weight?> = .init()
    let changeCurrentWeight: PublishSubject<Weight?> = .init()
    let error: PublishSubject<Error?> = .init()

    private let disposeBag = DisposeBag()
    private let rawDailyWeights: BehaviorRelay<[DailyWeight]> = .init(value: [])

    init() {
        targetWeight.accept(52.1)
        startWeight.accept(60.2)
        fillWeights()
        
        changeStartWeight
            .subscribe { [weak self] weight in
                self?.changeStartWeight(to: weight)
            }
            .disposed(by: disposeBag)
        
        changeTargetWeight
            .bind(onNext: { [weak self] weight in
                self?.changeTargetWeight(to: weight)
            })
            .disposed(by: disposeBag)
        
        changeCurrentWeight
            .bind(onNext: { [weak self] weight in
                self?.changeCurrentWeight(to: weight)
            })
            .disposed(by: disposeBag)
        
        Observable
            .combineLatest(rawDailyWeights, activePeriod)
            .map(dailyWeights)
            .bind(to: dailyWeights)
            .disposed(by: disposeBag)
    }
}

private extension RandomWeightDataSource {
    func fillWeights() {
        guard let startWeight = startWeight.value else {
            return
        }
        let startDate = Date.dateDaysAgo(150)
        let weights: [DailyWeight] = [.init(date: startDate, weight: startWeight)]
        var latestWeight = startWeight
        var dailyWeights = (1...149).reversed().reduce(into: weights) { result, dayIndex in
            var weight = Double.random(in: -1.1...1) + latestWeight
        
            if let minWeightForSeed = targetWeight.value, weight < minWeightForSeed {
                weight = minWeightForSeed
            }
            latestWeight = weight
            let date = Date.dateDaysAgo(dayIndex)
            let avoidPeriodStartPoints = dayIndex == 6 || dayIndex == 30
            if arc4random()%2 == 0 || avoidPeriodStartPoints {
                result.append(.init(date: date, weight: weight))
            } else {
                result.append(.init(date: date, weight: nil))
            }
        }
        
        dailyWeights[144] = .init(date: Date.dateDaysAgo(6), weight: 60.2)
        dailyWeights[145] = .init(date: Date.dateDaysAgo(5), weight: nil)
        dailyWeights[146] = .init(date: Date.dateDaysAgo(4), weight: 58)
        dailyWeights[147] = .init(date: Date.dateDaysAgo(3), weight: nil)
        dailyWeights[148] = .init(date: Date.dateDaysAgo(2), weight: nil)
        dailyWeights[149] = .init(date: Date.dateDaysAgo(1), weight: nil)

        if let currentWeight = self.currentWeight.value {
            dailyWeights.append(.init(date: Date(), weight: currentWeight))
        } else {
            dailyWeights.append(.init(date: Date(), weight: nil))
        }
        
        rawDailyWeights.accept(dailyWeights)
    }
    
    func dailyWeights(weights: [DailyWeight], period: Period) -> [DailyWeight] {
        return weights.compactMap { weight -> DailyWeight? in
            let latest: Date
            switch period {
            case .year:
                latest = Date().addingTimeInterval(-60 * 60 * 24 * 365)
            case .month:
                latest = Date().addingTimeInterval(-60 * 60 * 24 * 31)
            case .week:
                latest = Date().addingTimeInterval(-60 * 60 * 24 * 7)
            }
            return weight.date > latest ? weight : nil
        }
    }
    
    func changeCurrentWeight(to weight: Weight?) {
        var weights = rawDailyWeights.value
        let dailyWeight = DailyWeight(date: Date().noon, weight: weight)
        if weights.count > 150 {
            weights[150] = dailyWeight
        }
        rawDailyWeights.accept(weights)
        currentWeight.accept(weight)
    }
    
    func changeStartWeight(to weight: Weight?) {
        var weights = rawDailyWeights.value
        guard let unit = weights.first else {
            return
        }
        weights[0] = .init(date: unit.date.noon, weight: weight)
        rawDailyWeights.accept(weights)
        startWeight.accept(weight)
    }
    
    func changeTargetWeight(to weight: Weight?) {
        targetWeight.accept(weight)
        rawDailyWeights.accept(rawDailyWeights.value)
    }
}
