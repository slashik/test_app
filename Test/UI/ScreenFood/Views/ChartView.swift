//
//  ChartView.swift
//  Test
//
//  Created by Dmitry Yaskel on 20.03.2021.
//

import UIKit
import RxSwift
import RxCocoa

class ChartView: UIView {
    private struct Color {
        static let gradientColor1 = UIColor(red: CGFloat(171)/255, green: CGFloat(119)/255, blue: 1, alpha: 1)
        static let gradientColor2 = UIColor(red: CGFloat(148)/255, green: CGFloat(245)/255, blue: 1, alpha: 1)
    }
    struct ChartUnit {
        let title1: String?
        let subtitle1: String?
        let title2: String?
        let subtitle2: String?
        let value: CGFloat?
    }
    struct ChartLine {
        let title: String?
        let subtitle: String?
        let value: CGFloat
    }
    struct ChartData {
        let chartUnits: [ChartUnit]
        let chartLines: [ChartLine]
        let target: ChartLine
    }
    
    let chartData: BehaviorRelay<ChartData?> = .init(value: nil)
    
    private let disposeBag = DisposeBag()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        chartData
            .bind(onNext: { [weak self] _ in
                self?.setNeedsDisplay()
            })
            .disposed(by: disposeBag)
    }
    
    override func draw(_ rect: CGRect) {
        guard let chartData = chartData.value, !chartData.chartUnits.isEmpty else {
            return
        }
        var points = chartData.chartUnits.enumerated().reduce(into: [CGPoint]()) { result, enumerated in
            guard let coordinates = unitCoordinates(for: enumerated.element, at: enumerated.offset) else {
                return
            }
            result.append(coordinates)
        }
        if let firtst = points.first {
            let y = firtst.y - 5
            points = [CGPoint(x: -5, y: y)] + points
        }
        let y = unitY(value: chartData.target.value)
        points.append(.init(x: bounds.width - 10.0, y: y))
        points.append(.init(x: bounds.width + 5, y: y + 5))
        
        drawLines(chartData.chartLines)
        drawPath(points: points)
        drawPoints(points)
        drawTexts(units: chartData.chartUnits)
        drawTargetLine(unit: chartData.target)
    }
}

private extension ChartView {
    func drawPoints(_ points: [CGPoint]) {
        let context = UIGraphicsGetCurrentContext()
        context?.saveGState()
        context?.setFillColor(UIColor.black.cgColor)
        points.forEach { point in
            context?.move(to: point)
            
            let drawPoint = CGPoint(x: point.x - 1, y: point.y - 1)
            context?.drawPath(using: .stroke)
            context?.fillEllipse(in: .init(origin: drawPoint,
                                           size: .init(width: 3.0, height: 3.0)))
            context?.strokePath()
        }
        context?.restoreGState()
    }
    
    func drawPath(points: [CGPoint]) {
        guard points.count > 1 else {
            return
        }
        let context = UIGraphicsGetCurrentContext()
        context?.saveGState()

        var cp1: CGPoint = .zero
        var cp2: CGPoint = .zero
        var p0: CGPoint = .zero
        var p1: CGPoint = .zero
        var p2: CGPoint = .zero
        var p3: CGPoint = .zero

        var tensionBezier1: CGFloat = 0.3
        var tensionBezier2: CGFloat = 0.3

        var previousPoint1: CGPoint = .zero
        
        context?.setLineWidth(3)
        context?.setLineJoin(.round)
        context?.move(to: points[0])

        let count = points.count - 2
        for index in 0...count {
            p1 = points[index]
            p2 = points[index + 1]
            let maxTension: CGFloat = 0.2
            tensionBezier1 = maxTension
            tensionBezier2 = maxTension
            if index == 0 || index == points.count - 2 {
                tensionBezier1 = 0
                p0 = p1
            } else {
                p0 = previousPoint1
                if p2.y - p1.y == p1.y - p0.y {
                    tensionBezier1 = 0
                }
            }
            if index < points.count - 2 {
                p3 = points[index + 2]
                if p3.y - p2.y == p2.y - p1.y {
                    tensionBezier2 = 0
                }
            } else {
                p3 = p2
                tensionBezier2 = 0
            }

            if tensionBezier1 > maxTension {
                tensionBezier1 = maxTension
            }
            if tensionBezier2 > maxTension {
                tensionBezier2 = maxTension
            }

            cp1 = .init(x: p1.x + (p2.x - p1.x)/3,
                        y: p1.y - (p1.y - p2.y)/3 - (p0.y - p1.y)*tensionBezier1)

            cp2 = .init(x: p1.x + 2*(p2.x - p1.x)/3,
                        y: (p1.y - 2*(p1.y - p2.y)/3) + (p2.y - p3.y)*tensionBezier2)
            context?.addCurve(to: p2, control1: cp1, control2: cp2)
            previousPoint1 = p1
        }
        context?.replacePathWithStrokedPath()
        context?.clip()
        let gradient = CGGradient(colorsSpace: nil,
                                  colors: [Color.gradientColor1.cgColor,
                                           Color.gradientColor2.cgColor] as CFArray,
                                  locations: [0.0, 1.0])
        context?.drawLinearGradient(gradient!,
                                    start: CGPoint(x: chartFrame.midX, y: chartFrame.minY - 10),
                                    end: CGPoint(x: chartFrame.midX, y: chartFrame.maxY + 10),
                                    options: .drawsAfterEndLocation)
        context?.restoreGState()
    }
    
    func drawLines(_ lines: [ChartLine]) {
        lines.forEach { drawStrokeLine($0, color: #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 0.5088610112))}
    }
    
    func drawStrokeLine(_ line: ChartLine, color: UIColor) {
        let context = UIGraphicsGetCurrentContext()
        context?.saveGState()
        let targetValue = line.value
        let coordY = unitY(value: targetValue)
        context?.move(to: .init(x: -5, y: coordY))
        context?.addLine(to: .init(x: chartFrame.maxX, y: coordY))
        
        context?.setLineDash(phase: 0.0, lengths: [8, 5])
        context?.setLineWidth(1.0)
        context?.setLineCap(.butt)
        color.set()
        context?.strokePath()
        context?.restoreGState()
    }

    func drawTargetLine(unit: ChartLine) {
        drawStrokeLine(unit, color: .black)

        let targetValue = unit.value
        let coordY = unitY(value: targetValue)
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        let boldAttributes = [NSAttributedString.Key.font: UIFont(name: "OpenSans-Bold", size: 6)!,
                              NSAttributedString.Key.paragraphStyle: paragraphStyle]
        let regularAttributes = [NSAttributedString.Key.font: UIFont(name: "OpenSans-Regular", size: 7)!,
                                 NSAttributedString.Key.paragraphStyle: paragraphStyle]
        let tileRect = CGRect(x:bounds.width - 35, y: coordY - 25, width: 30, height: 30)
        unit.title?.draw(with: tileRect, options: .usesLineFragmentOrigin, attributes: regularAttributes, context: nil)
        
        let subtitleRect = CGRect(x:bounds.width - 35, y: coordY - 15, width: 30, height: 30)
        unit.subtitle?.draw(with: subtitleRect, options: .usesLineFragmentOrigin, attributes: boldAttributes, context: nil)
    }
    
    func drawTexts(units: [ChartUnit]) {
        units.enumerated().forEach { index, unit in
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center
            
            let boldAttributes = [NSAttributedString.Key.font: UIFont(name: "OpenSans-Bold", size: 11)!,
                                  NSAttributedString.Key.paragraphStyle: paragraphStyle]
            let regularAttributes = [NSAttributedString.Key.font: UIFont(name: "OpenSans-Regular", size: 11)!,
                                     NSAttributedString.Key.paragraphStyle: paragraphStyle]
            
            let weightRect = CGRect(x: unitX(at: index) - 15, y: weightFrame.midY - 15, width: 30, height: 30)
            unit.title1?.draw(with: weightRect, options: .usesLineFragmentOrigin, attributes: boldAttributes, context: nil)
            
            let measureRect = CGRect(x: unitX(at: index) - 15, y: weightFrame.midY, width: 30, height: 30)
            unit.subtitle1?.draw(with: measureRect, options: .usesLineFragmentOrigin, attributes: regularAttributes, context: nil)
            
            
            let dayRect = CGRect(x: unitX(at: index) - 15, y: datesFrame.midY - 15, width: 50, height: 30)
            unit.title2?.draw(with: dayRect, options: .usesLineFragmentOrigin, attributes: regularAttributes, context: nil)
            
            let monthRect = CGRect(x: unitX(at: index) - 15, y: datesFrame.midY, width: 50, height: 30)
            unit.subtitle2?.draw(with: monthRect, options: .usesLineFragmentOrigin, attributes: boldAttributes, context: nil)
        }
    }
}

private extension ChartView {
    var weightFrame: CGRect {
        let height: CGFloat = 60.0
        return .init(x: 0.0, y: 0.0, width: bounds.width, height: height)
    }
    
    var datesFrame: CGRect {
        let height: CGFloat = 60.0
        return .init(x: 0.0, y: bounds.height - height, width: bounds.width, height: height)
    }
    
    var chartFrame: CGRect {
        return .init(x: 0.0, y: weightFrame.height, width: bounds.width, height: bounds.height - weightFrame.height - datesFrame.height)
    }
    
    func unitCoordinates(for unit: ChartUnit, at index: Int) -> CGPoint? {
        guard let units = chartData.value?.chartUnits else {
            return nil
        }
        let unit = units[index]
        guard let value = unit.value else {
            return nil
        }
        return .init(x: unitX(at: index),
                     y: unitY(value: value))
    }
    
    func unitX(at index: Int) -> CGFloat {
        guard let units = chartData.value?.chartUnits else {
            return 0.0
        }
        let offsetLeft: CGFloat = 20.0
        let offsetRight: CGFloat = 40.0
        return (chartFrame.width - offsetLeft - offsetRight)/CGFloat(units.count - 1) * CGFloat(index) + offsetLeft
    }
    
    func unitY(value: CGFloat) -> CGFloat {
        return chartFrame.height * 0.8 * (1 - value) + chartFrame.minY
    }
}
