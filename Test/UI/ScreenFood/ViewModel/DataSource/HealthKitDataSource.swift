//
//  HealthKitDataSource.swift
//  Test
//
//  Created by Dmitry Yaskel on 27.03.2021.
//

import Foundation
import HealthKit
import RxSwift
import RxCocoa

class HealthKitDataSource: WeightDataSourceType {
    enum SourceError: LocalizedError {
        case notImplemented
        
        var errorDescription: String? {
            switch self {
            case .notImplemented:
                return "Partially implemented. Data in HealthKit will not be changed."
            }
        }
    }
    let startWeight: BehaviorRelay<Weight?> = .init(value: nil)
    let targetWeight: BehaviorRelay<Weight?> = .init(value: nil)
    let currentWeight: BehaviorRelay<Weight?> = .init(value: nil)
    let dailyWeights: BehaviorRelay<[DailyWeight]> = .init(value: [])
    let activePeriod: BehaviorRelay<Period> = .init(value: .week)
    let changeStartWeight: PublishSubject<Weight?> = .init()
    let changeTargetWeight: PublishSubject<Weight?> = .init()
    let changeCurrentWeight: PublishSubject<Weight?> = .init()
    let error: PublishSubject<Error?> = .init()

    private let disposeBag = DisposeBag()
    private let weights: BehaviorRelay<[DailyWeight]> = .init(value: [])

    init() {
        fillSource()
        checkAvailiability()
        bindings()
    }
}

private extension HealthKitDataSource {
    func fillSource() {
        targetWeight.accept(52.1)
    }
    
    func bindings() {
        activePeriod
            .bind(onNext: { [weak self] _ in
                self?.reloadData()
            })
            .disposed(by: disposeBag)
        
        weights
            .bind { [weak self] _ in
                self?.mergeWeightsWithEmptyDays()
            }
            .disposed(by: disposeBag)
        
        changeStartWeight
            .bind(onNext: { [weak self] weight in
                self?.startWeight.accept(weight)
                self?.error.onNext(SourceError.notImplemented)
            })
            .disposed(by: disposeBag)
        
        changeTargetWeight
            .bind(onNext: { [weak self] weight in
                self?.targetWeight.accept(weight)
                self?.reloadData()
            })
            .disposed(by: disposeBag)
        
        changeCurrentWeight
            .bind(onNext: { [weak self] weight in
                self?.currentWeight.accept(weight)
                self?.error.onNext(SourceError.notImplemented)
            })
            .disposed(by: disposeBag)
    }
    
    func checkAvailiability() {
        guard HKHealthStore.isHealthDataAvailable(),
              let bodyMass = HKObjectType.quantityType(forIdentifier: .bodyMass) else {
            return
        }
        let healthKitTypesToWrite: Set<HKSampleType> = [bodyMass]
        
        let healthKitTypesToRead: Set<HKObjectType> = [bodyMass]
        
        HKHealthStore().requestAuthorization(toShare: healthKitTypesToWrite,
                                             read: healthKitTypesToRead) { [weak self] success, error in
            guard success else {
                return
            }
            self?.reloadData()
        }
    }
    
    func mergeWeightsWithEmptyDays() {
        let weights = self.weights.value
        let daysInPeriod = Date.daysInPeriod(activePeriod.value)
                
        var previousDate = Date(timeIntervalSince1970: 0)
        let removedDuplicates = weights.reversed().reduce(into: [DailyWeight]()) { result, weight in
            guard !Calendar.current.isDate(previousDate, inSameDayAs: weight.date) else {
                return
            }
            previousDate = weight.date
            result.append(weight)
        }
        
        let emptyDates = (0..<daysInPeriod).reduce(into: [DailyWeight]()) { result, index in
            let date = Date.dateDaysAgo(index).noon
            guard !removedDuplicates.contains(where: { $0.date.noon == date }) else {
                return
            }
            result.append(.init(date: date, weight: nil))
        }
        
        let allDatesForPeriod = (emptyDates + removedDuplicates).sorted(by: { $0.date < $1.date })
        dailyWeights.accept(allDatesForPeriod)
    }
    
    func reloadData() {
        reloadValues()
        obtainWeightsForCurrentPeriod { [weak self] weights in
            self?.weights.accept(weights)
        }
    }
    
    func obtainWeightsForCurrentPeriod(completion: @escaping ([DailyWeight]) -> Void) {
        obtainWeightsFromDate(date: currentPeriodStartDate, completion: completion)
    }
    
    func reloadValues() {
        obtainWeightsFromDate(date: Date.distantPast) { [weak self] samples in
            var samples = samples
            samples.sort(by: { $0.date < $1.date })
            let startWeight = samples.first?.weight
            let currentWeight = samples.last?.weight
            DispatchQueue.main.async {
                self?.startWeight.accept(startWeight)
                self?.currentWeight.accept(currentWeight)
            }
        }
    }
    
    func obtainWeightsFromDate(date: Date, completion: @escaping ([DailyWeight]) -> Void) {
        guard let weightSampleType = HKSampleType.quantityType(forIdentifier: .bodyMass) else {
            return
        }
        let mostRecentPredicate = HKQuery.predicateForSamples(withStart: date,
                                                              end: Date(),
                                                              options: [])
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
        let limit = 100500
        let sampleQuery = HKSampleQuery(sampleType: weightSampleType,
                                        predicate: mostRecentPredicate,
                                        limit: limit,
                                        sortDescriptors: [sortDescriptor]) { _, samples, _ in
            let weights = (samples as? [HKQuantitySample])?.compactMap { sample -> DailyWeight? in
                return .init(date: sample.startDate,
                             weight: sample.quantity.doubleValue(for: HKUnit.gramUnit(with: .kilo)))
            }
            DispatchQueue.main.async {
                completion(weights ?? [])
            }
        }
        HKHealthStore().execute(sampleQuery)
    }
}

private extension HealthKitDataSource {
    var currentPeriodStartDate: Date {
        Date.startDateForPeriod(activePeriod.value)
    }
}
