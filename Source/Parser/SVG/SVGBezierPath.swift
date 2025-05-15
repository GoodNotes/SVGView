//import Foundation
//
//
//public final class SVGBezierPath {
//    
//    // MARK: - Properties
//    
//    public var cgPath: CGPath
//    
//    public var lineWidth: CGFloat = 1.0
//    
//    public var lineCapStyle: CGLineCap = .butt
//    
//    public var lineJoinStyle: CGLineJoin = .miter
//    
//    public var miterLimit: CGFloat = 10
//    
//    public var flatness: CGFloat = 0.6
//    
//    public var usesEvenOddFillRule: Bool = false
//    
//    public var lineDash: (phase: CGFloat, lengths: [CGFloat]) = (0.0, [])
//    
//    // MARK: - Initialization
//    
//    public init(cgPath path: CGPath = CGPath()) {
//        
//        self.cgPath = path
//    }
//    
//    public init(rect: CGRect) {
//        
//        var path = CGPath()
//        
//        path.addRect(rect)
//        
//        self.cgPath = path
//    }
//    
//    public init(ovalIn rect: CGRect) {
//        
//        var path = CGPath()
//        
//        path.addEllipse(in: rect)
//        
//        self.cgPath = path
//    }
//    
//    public convenience init(roundedRect rect: CGRect, cornerRadius: CGFloat) {
//        
//        self.init(roundedRect: rect, byRoundingCorners: .allCorners, cornerRadii: CGSize(width: cornerRadius, height: cornerRadius))
//    }
//    
//    public init(roundedRect rect: CGRect, byRoundingCorners corners: UIRectCorner, cornerRadii: CGSize) {
//        
//        var path = CGPath()
//        
//        func addCurve(_ control1: CGPoint, _ control2: CGPoint, _ end: CGPoint) {
//            
//            path.addCurve(to: end, control1: control1, control2: control2)
//        }
//        
//        let topLeft = rect.origin
//        let topRight = CGPoint(x: rect.maxX, y: rect.minY)
//        let bottomRight = CGPoint(x: rect.maxX, y: rect.maxY)
//        let bottomLeft = CGPoint(x: rect.minX, y: rect.maxY)
//        
//        if corners.contains(.topLeft) {
//            path.move(to: CGPoint(x: topLeft.x+cornerRadii.width, y:topLeft.y))
//        } else {
//            path.move(to: CGPoint(x: topLeft.x, y:topLeft.y))
//        }
//        if corners.contains(.topRight) {
//            path.addLine(to: CGPoint(x: topRight.x-cornerRadii.width, y: topRight.y))
//            addCurve(CGPoint(x: topRight.x, y: topRight.y),
//                     CGPoint(x: topRight.x, y: topRight.y+cornerRadii.height),
//                     CGPoint(x: topRight.x, y: topRight.y+cornerRadii.height))
//        } else {
//            path.addLine(to: CGPoint(x: topRight.x, y: topRight.y))
//        }
//        if corners.contains(.bottomRight) {
//            path.addLine(to: CGPoint(x: bottomRight.x, y: bottomRight.y-cornerRadii.height))
//            addCurve(CGPoint(x: bottomRight.x, y: bottomRight.y),
//                     CGPoint(x: bottomRight.x-cornerRadii.width, y: bottomRight.y),
//                     CGPoint(x: bottomRight.x-cornerRadii.width, y: bottomRight.y))
//        } else {
//            path.addLine(to: CGPoint(x: bottomRight.x, y: bottomRight.y))
//        }
//        if corners.contains(.bottomLeft) {
//            path.addLine(to: CGPoint(x: bottomLeft.x+cornerRadii.width, y: bottomLeft.y))
//            addCurve(CGPoint(x: bottomLeft.x, y: bottomLeft.y),
//                     CGPoint(x: bottomLeft.x, y: bottomLeft.y-cornerRadii.height),
//                     CGPoint(x:bottomLeft.x, y: bottomLeft.y-cornerRadii.height))
//        } else {
//            path.addLine(to: CGPoint(x: bottomLeft.x, y: bottomLeft.y))
//        }
//        if corners.contains(.topLeft) {
//            path.addLine(to: CGPoint(x: topLeft.x, y: topLeft.y+cornerRadii.height))
//            addCurve(CGPoint(x: topLeft.x, y: topLeft.y),
//                     CGPoint(x: topLeft.x+cornerRadii.width, y: topLeft.y),
//                     CGPoint(x: topLeft.x+cornerRadii.width, y: topLeft.y))
//        } else {
//            path.addLine(to: CGPoint(x: topLeft.x, y: topLeft.y))
//        }
//        
//        path.closeSubpath()
//        
//        self.cgPath = path
//    }
//        
// 
//    
//    // MARK: - Constructing a Path
//    
//    public func move(to point: CGPoint) {
//        
//        cgPath.elements.append(.moveToPoint(point))
//    }
//    
//    public func addLine(to point: CGPoint) {
//        
//        cgPath.elements.append(.addLineToPoint(point))
//    }
//    
//    public func addCurve(to endPoint: CGPoint, controlPoint1: CGPoint, controlPoint2: CGPoint) {
//        
//        cgPath.elements.append(.addCurveToPoint(controlPoint1, controlPoint2, endPoint))
//    }
//    
//    public func addQuadCurve(to endPoint: CGPoint, controlPoint: CGPoint) {
//        
//        cgPath.elements.append(.addQuadCurveToPoint(controlPoint, endPoint))
//    }
//    
//    public func close() {
//        
//        cgPath.elements.append(.closeSubpath)
//    }
//    
//    public func addArc(with center: CGPoint, radius: CGFloat, startAngle: CGFloat, endAngle: CGFloat, clockwise: Bool) {
//        
//        fatalError("Not implemented")
//    }
//    
//  
//}
