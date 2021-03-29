//
//  WeightDataSourceType.swift
//  Test
//
//  Created by Dmitry Yaskel on 28.03.2021.
//

import Foundation
import RxSwift
import RxCocoa

typealias Weight = Double

struct DailyWeight {
    let date: Date
    let weight: Weight?
}

protocol WeightDataSourceType {
    var startWeight: BehaviorRelay<Weight?> { get }
    var targetWeight: BehaviorRelay<Weight?> { get }
    var currentWeight: BehaviorRelay<Weight?> { get }
    var activePeriod: BehaviorRelay<Period> { get }
    var dailyWeights: BehaviorRelay<[DailyWeight]> { get }
    var changeStartWeight: PublishSubject<Weight?> { get }
    var changeTargetWeight: PublishSubject<Weight?> { get }
    var changeCurrentWeight: PublishSubject<Weight?> { get }
    var error: PublishSubject<Error?> { get }
}
