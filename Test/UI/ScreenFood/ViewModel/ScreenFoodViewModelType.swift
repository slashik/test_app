//
//  ScreenFoodViewModelType.swift
//  Test
//
//  Created by Dmitry Yaskel on 21.03.2021.
//

import RxCocoa
import RxSwift

enum Period {
    case week
    case month
    case year
}

protocol ScreenFoodViewModelType {
    var startWeight: BehaviorRelay<WeightRepresentation?> { get }
    var targetWeight: BehaviorRelay<WeightRepresentation?> { get }
    var currentWeight: BehaviorRelay<WeightRepresentation?> { get }
    var activePeriod: BehaviorRelay<Period> { get }
    var chartData: BehaviorRelay<ChartView.ChartData?>  { get }
    var chartPeriod: BehaviorRelay<(earliest: Date, latest: Date)?> { get }
    var changeStartWeight: PublishSubject<Weight?> { get }
    var changeTargetWeight: PublishSubject<Weight?> { get }
    var changeCurrentWeight: PublishSubject<Weight?> { get }
    var error: PublishSubject<Error?> { get }
}
