//
//  File.swift
//  
//
//  Created by Ryan Mckinney on 2/9/23.
//

import Foundation

#if os(iOS)
import UIKit
public typealias UniversalWindow = UIWindow
public typealias UniversalResponder = UIResponder
public extension UniversalWindow {
    
    static func getKeyWindow() -> UniversalWindow? {
        return UIApplication.shared.windows.first(where: \.isKeyWindow)
    }
    
    var safeAreaLayoutFrame: CGRect {
//        print("[ios] safeAreaLayoutFrame: \(safeAreaLayoutGuide.layoutFrame)")
        return safeAreaLayoutGuide.layoutFrame
    }
}


#elseif os(macOS)
import AppKit
public typealias UniversalWindow = NSWindow
public typealias UniversalResponder = NSResponder
public extension UniversalWindow {
    
    static func getKeyWindow() -> UniversalWindow? {
        return NSApplication.shared.windows.first(where: \.isKeyWindow)
    }
    var bounds: CGRect {
        if let bounds = contentView?.bounds {
            print("[UniversalWindow] bounds: \(bounds)")
            return NSRectToCGRect(bounds)
        } else {
            print("[UniversalWindow] bounds -- ZERO")
            return CGRect.zero
        }
    }
    
    func addSubview(_ view: NSView) {
        print("mac [UniversalWindow] addSubview")
        if let cView = contentView {
            print("mac [UniversalWindow] addSubview -- window success")
            cView.addSubview(view)
        } else {
            print("mac [UniversalWindow] addSubview -- NO CONTENT VIEW")
        }
    }
    
    func bringSubviewToFront(_ view: NSView) {
        print("[UniversalWindow] bringSubviewToFront")
        let superLayer = view.layer?.superlayer
        view.layer?.removeFromSuperlayer()
        if let viewLayer = view.layer {
            superLayer?.addSublayer(viewLayer)
        }
    }
    
    var layer: CALayer {
        if let layer = contentView?.layer {
            print("[UniversalWindow] layer present")
            return layer
        } else {
            print("[UniversalWindow] NO layer")
            return CALayer.init()
        }
    }
    
    var safeAreaLayoutFrame: CGRect {
//        let contentRect = frame
//        let contentRect = contentLayoutRect
        let contentRect = contentLayoutRect
        print("[UniversalWindow] contentRect: \(contentRect)")
        return NSRectToCGRect(contentRect)
        
    }
}
extension CGRect {
    public func inset(by insets: NSEdgeInsets) -> CGRect {
        return CGRect(x: self.minX + insets.left,
                      y: self.minY + insets.top, width: self.width - insets.left - insets.right, height: self.height - insets.top - insets.bottom)
    }
}
#endif







import SwiftUI

#if os(iOS) || os(tvOS)
public typealias PlatformView = UIView
public typealias PlatformViewController = UIViewController
public typealias PlatformViewRepresentable = UIViewRepresentable
public typealias PlatformEdgeInsets = UIEdgeInsets
#elseif os(macOS)
public typealias PlatformView = NSView
public typealias PlatformViewController = NSViewController
public typealias PlatformViewRepresentable = NSViewRepresentable

public typealias PlatformEdgeInsets = NSEdgeInsets
extension PlatformEdgeInsets {
    static var zero: PlatformEdgeInsets { NSEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)}
}
#endif

/// Implementers get automatic `UIViewRepresentable` conformance on iOS
/// and `NSViewRepresentable` conformance on macOS.
public protocol PlatformAgnosticViewRepresentable: PlatformViewRepresentable {
    associatedtype PlatformViewType

    func makePlatformView(context: Context) -> PlatformViewType
    func updatePlatformView(_ platformView: PlatformViewType, context: Context)
}

#if os(iOS) || os(tvOS)
public extension PlatformAgnosticViewRepresentable where UIViewType == PlatformViewType {
    func makeUIView(context: Context) -> UIViewType {
        makePlatformView(context: context)
    }

    func updateUIView(_ uiView: UIViewType, context: Context) {
        updatePlatformView(uiView, context: context)
    }
}


public extension PlatformView {
    
    func setBackgroundClear() {
        backgroundColor = .clear
    }
    
}



#elseif os(macOS)
public extension PlatformAgnosticViewRepresentable where NSViewType == PlatformViewType {
    func makeNSView(context: Context) -> NSViewType {
        makePlatformView(context: context)
    }

    func updateNSView(_ nsView: NSViewType, context: Context) {
        updatePlatformView(nsView, context: context)
    }
}


public extension PlatformView {
    
    func setBackgroundClear() {
        layer?.backgroundColor = .clear
    }
    
    
}

#endif


///MARK color Bridge
///
///
#if os(macOS)
import AppKit

/**
 This typealias bridges platform-specific colors to simplify
 multi-platform support.
 */
public typealias UniversalColor = NSColor
extension UniversalColor {
    static let txt: UniversalColor = .textColor
    static let txtSecondary: UniversalColor = .secondaryLabelColor
    static let txtLink: UniversalColor = .linkColor
    
    static func dynamic(_ light: Int, lightAlpha: CGFloat = 1.0, _ dark: Int, darkAlpha: CGFloat = 1.0) -> UniversalColor {
        let lightColor = NSColor(hex: light).withAlphaComponent(lightAlpha)
        let darkColor = NSColor(hex: dark).withAlphaComponent(darkAlpha)
        return self.init(name: nil, dynamicProvider: { appearance in
            guard let appearanceName = appearance.bestMatch(from: [.aqua, .darkAqua]) else { return lightColor }
            switch appearanceName {
            case .aqua:
                return lightColor
            case .darkAqua:
                return darkColor
            default:
                return lightColor
            }
        })
    }
    
    convenience init(hex: Int) {
            let r = (hex & 0xff0000) >> 16
            let g = (hex & 0xff00) >> 8
            let b = hex & 0xff
            
            self.init(red: CGFloat(r) / 0xff, green: CGFloat(g) / 0xff, blue: CGFloat(b) / 0xff, alpha: 1)
        }
    
}

#endif


#if os(iOS) || os(tvOS) || os(watchOS)
import UIKit

/**
 This typealias bridges platform-specific colors to simplify
 multi-platform support.
 */
public typealias UniversalColor = UIColor
extension UniversalColor {
    static let txt: UniversalColor = UIColor.label
    static let txtSecondary: UniversalColor = UIColor.secondaryLabel
    static let txtLink: UniversalColor = UIColor.link
    
    static func dynamic(_ light: Int, lightAlpha: CGFloat = 1.0, _ dark: Int, darkAlpha: CGFloat = 1.0) -> UniversalColor {
        UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(hex: dark).withAlphaComponent(darkAlpha)
                : UIColor(hex: light).withAlphaComponent(lightAlpha)
        }
    }
    
    convenience init(hex: Int) {
        self.init(
            red: (hex >> 16) & 0xff,
            green: (hex >> 8) & 0xff,
            blue: hex & 0xff
        )
    }
    convenience init(red: Int, green: Int, blue: Int) {
        self.init(
            red: CGFloat(red),
            green: CGFloat(green),
            blue: CGFloat(blue),
            alpha: 1.0
        )
    }
}
#endif
import SwiftUI

extension UniversalColor {
    var swiftUI: Color { Color(self) }
    
    
    func toRGB() -> RGB {
        let components = self.cgColor.components
        let r: CGFloat = components?[0] ?? 0.0
        let g: CGFloat = components?[1] ?? 0.0
        let b: CGFloat = components?[2] ?? 0.0
        return RGB(r: r, g: g, b: b)
    }
    
    struct RGB {
        let r: CGFloat
        let g: CGFloat
        let b: CGFloat
        func hexString() -> String {
            let hex = String.init(format: "#%02lX%02lX%02lX", lroundf(Float(r * 255)), lroundf(Float(g * 255)), lroundf(Float(b * 255)))
            print("HexString: \(hex)")
            return hex
        }
    }
    
    func offset(by offset: CGFloat) -> UniversalColor {
        let (h, s, b, a) = hsba
        var newHue = h - offset

        /// make it go back to positive
        while newHue <= 0 {
            newHue += 1
        }
        let normalizedHue = newHue.truncatingRemainder(dividingBy: 1)
        return UniversalColor(hue: normalizedHue, saturation: s, brightness: b, alpha: a)
    }

    var hsba: (h: CGFloat, s: CGFloat, b: CGFloat, a: CGFloat) {
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        self.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return (h: h, s: s, b: b, a: a)
    }

    
}

