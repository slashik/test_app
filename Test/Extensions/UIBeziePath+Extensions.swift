//
//  UIBeziePath+Extensions.swift
//  Test
//
//  Created by Dmitry Yaskel on 31.03.2021.
//

import UIKit

extension UIBezierPath {
    
    static func from(_ points: [CGPoint]) -> UIBezierPath {
        let path = UIBezierPath()
        guard let first = points.first, points.count > 1 else {
            return path
        }
        path.move(to: first)
        
        var derivatives: [CGPoint] = []
        for index in 0 ..< points.count {
            let prevIndex = max(index - 1, 0)
            let nextIndex = min(index + 1, points.count - 1)
            
            let prev = points[prevIndex]
            let next = points[nextIndex]
            
            let diffX = next.x - prev.x
            let diffY = next.y - prev.y

            let absX = abs(diffX)
            let absY = abs(diffY)
            var tensionX: CGFloat = 0.13
            var tensionY: CGFloat = 0.13
            if absX > 100, absY > 5 {
                tensionX = 0.2
            }
            if absY > 100, absX > 5 {
                tensionY = 0.2
            }
            
            let derivative = CGPoint(x: diffX * tensionX,
                                     y: diffY * tensionY)
            
            derivatives.append(derivative)
        }
                
        for index in 1 ..< points.count {
            let prevPoint = points[index - 1]
            let prevDerivative = derivatives[index - 1]
            let nextPoint = points[index]
            let nextDerivative = derivatives[index]
            
            let cp1 = CGPoint(x: prevPoint.x + prevDerivative.x,
                              y: prevPoint.y + prevDerivative.y)
            let cp2 = CGPoint(x: nextPoint.x - nextDerivative.x,
                              y: nextPoint.y - nextDerivative.y)
            path.addCurve(to: points[index], controlPoint1: cp1, controlPoint2: cp2)
        }
        
        return path
    }
}
