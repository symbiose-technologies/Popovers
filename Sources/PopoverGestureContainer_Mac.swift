//
//  PopoverGestureContainer.swift
//  Popovers
//
//  Created by A. Zheng (github.com/aheze) on 12/23/21.
//  Copyright © 2022 A. Zheng. All rights reserved.
//

#if os(macOS)
import SwiftUI

/// A hosting view for `PopoverContainerView` with tap filtering.
class PopoverGestureContainer: NSView {
    /// A closure to be invoked when this view is inserted into a window's view hierarchy.
    var onMovedToWindow: (() -> Void)?

    
    /// If this is nil, the view hasn't been laid out yet.
    var previousBounds: CGRect?

    //Copilot: convert the above code to the corresponding AppKit, macOS implementation
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)

        
        /// Allow resizing.
        autoresizingMask = [.width, .height]
    }

    
    
    override func layout() {
        super.layout()

        /// Only update frames on a bounds change.
        if let previousBounds = previousBounds, previousBounds != bounds {
            /// Orientation or screen bounds changed, so update popover frames.
            popoverModel.updateFramesAfterBoundsChange()
        }

        /// Store the bounds for later.
        previousBounds = bounds
        
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()

        /// There might not be a window yet, but that's fine. Just wait until there's actually a window.
        guard let window = window else { return }

        print("[PopoverGestureContainer] viewDidMoveToWindow ignores mouseEvents: \(window.ignoresMouseEvents)")
       
        
        /// Create the SwiftUI view that contains all the popovers.
        let popoverContainerView = PopoverContainerView(popoverModel: popoverModel)
            .environment(\.window, window) /// Inject the window.
        
        //adding an nshostingview doesn't work
        
        
        
        let hostingController = NSHostingController(rootView: popoverContainerView)
        hostingController.view.frame = bounds
        hostingController.view.wantsLayer = true
        hostingController.view.autoresizingMask = [.width, .height]
        
        
        
        addSubview(hostingController.view)

        /// Ensure the view is laid out so that SwiftUI animations don't stutter.
//        resizeSubviews(withOldSize: self.frame.size)
//        layoutSubtreeIfNeeded()

        /// Let the presenter know that its window is available.
        onMovedToWindow?()
//        DebugHelper.printResponderChain(from: self)
//        print("$$$$$$$$$$$$$$$$$$$$$$$$$$ Making self firstResponder")
//        window.makeFirstResponder(self)
        DebugHelper.printResponderChain(from: self)


        self.addCloseOnOutsideClick()
    }
    
//    override func mouseDragged(with event: NSEvent) {
//        print("[PopoverGestureContainer] mouseDragged event: \(event)")
//        super.mouseDragged(with: event)
//    }
//    override func mouseUp(with event: NSEvent) {
//        print("[PopoverGestureContainer] mouseUp event: \(event)")
//        super.mouseUp(with: event)
//    }
//
//    override func scrollWheel(with event: NSEvent) {
//        print("[PopoverGestureContainer] scrollWheel event: \(event)")
//        super.scrollWheel(with: event)
//    }
//
//    override func touchesBegan(with event: NSEvent) {
//        print("[PopoverGestureContainer] touchesBegan event: \(event)")
//        super.touchesBegan(with: event)
//    }
//    override func touchesEnded(with event: NSEvent) {
//        print("[PopoverGestureContainer] touchesEnded event: \(event)")
//        super.touchesEnded(with: event)
//    }
//    override func touchesMoved(with event: NSEvent) {
//        print("[PopoverGestureContainer] touchesMoved event: \(event)")
//        super.touchesMoved(with: event)
//    }
//    override func touchesCancelled(with event: NSEvent) {
//        print("[PopoverGestureContainer] touchesCancelled event: \(event)")
//        super.touchesCancelled(with: event)
//    }
//
//    override func mouseEntered(with event: NSEvent) {
//        print("[PopoverGestureContainer] touchesMoved event: \(event)")
//
//    }


    
    func addTestView(frame: CGRect) {
        let rect = NSRect(x: frame.minX, y: frame.minY, width: frame.width, height: frame.height)
        let rectView = NSView(frame: rect)
        rectView.wantsLayer = true
        rectView.layer?.backgroundColor = NSColor.green.cgColor

        self.addSubview(rectView)
        /// Ensure the view is laid out so that SwiftUI animations don't stutter.
        resizeSubviews(withOldSize: self.frame.size)
        layoutSubtreeIfNeeded()
    }
    func addTestCircleView(point: CGPoint) {
        let diameter: CGFloat = 20
        let rect = CGRect(x: point.x - diameter / 2, y: point.y - diameter / 2, width: diameter, height: diameter)
        let circleView = NSView(frame: rect)
        circleView.wantsLayer = true
        circleView.layer?.backgroundColor = NSColor.red.cgColor
        circleView.layer?.cornerRadius = diameter / 2

        self.addSubview(circleView)
        /// Ensure the view is laid out so that SwiftUI animations don't stutter.
        resizeSubviews(withOldSize: self.frame.size)
        layoutSubtreeIfNeeded()
    }

    
    override func hitTest(_ point: NSPoint) -> NSView? {
        print("[PopoverGestureContainer] hitTest event: \(point) -- current Popups: \(popoverModel.popovers.count)")
        print("[PopoverGestureContainer] myFrame: \(frame) myBounds: \(bounds)")
//        self.addTestCircleView(point: point)
        DebugHelper.printResponderChain(from: self)
        /// Only loop through the popovers that are in this window.
        let popovers = popoverModel.popovers

        /// The current popovers' frames
        let popoverFrames = popovers.map { $0.context.frame }
        
        /// Loop through the popovers and see if the touch hit it.
        /// `reversed` to start from the most recently presented popovers, working backwards.
        for popover in popovers.reversed() {
            print("[PopoverGestureContainer] Popover Frame: \(popover.context.frame)")
//            self.addTestView(frame: popover.context.frame)
//            self.addTestView(frame: popover.context.frame)
            /// Check it the popover was hit.
            if popover.context.frame.contains(point) {
                /// Dismiss other popovers if they have `tapOutsideIncludesOtherPopovers` set to true.
                for popoverToDismiss in popovers {
                    if
                        popoverToDismiss != popover,
                        !popoverToDismiss.context.frame.contains(point) /// The popover's frame doesn't contain the touch point.
                    {
                        dismissPopoverIfNecessary(popoverFrames: popoverFrames, point: point, popoverToDismiss: popoverToDismiss)
                    }
                }
                
                /// Receive the touch and block it from going through.
                print("[PopoverGestureContainer] hitTest A FOUND!")
//                if let parent = superview {
//                    return parent.hitTest(point)
//                }
//                return nil
                return super.hitTest(point)
            }
            
            /// The popover was not hit, so let it know that the user tapped outside.
            popover.attributes.onTapOutside?()
            
            /// If the popover has `blocksBackgroundTouches` set to true, stop underlying views from receiving the touch.
            if popover.attributes.blocksBackgroundTouches {
                let allowedFrames = popover.attributes.blocksBackgroundTouchesAllowedFrames()
                
                if allowedFrames.contains(where: { $0.contains(point) }) {
                    dismissPopoverIfNecessary(popoverFrames: popoverFrames, point: point, popoverToDismiss: popover)
                    
                    return nil
                } else {
                    /// Receive the touch and block it from going through.
                    return super.hitTest(point)
                }
            }
            
            /// Check if the touch hit an excluded view. If so, don't dismiss it.
            if popover.attributes.dismissal.mode.contains(.tapOutside) {
                let excludedFrames = popover.attributes.dismissal.excludedFrames()
                if excludedFrames.contains(where: { $0.contains(point) }) {
                    /**
                     The touch hit an excluded view, so don't dismiss it.
                     However, if the touch hit another popover, block it from passing through.
                     */
                    if popoverFrames.contains(where: { $0.contains(point) }) {
                        return super.hitTest(point)
                    } else {
                        return nil
                    }
                }
            }
            
            /// All checks did not pass, which means the touch landed outside the popover. So, dismiss it if necessary.
            dismissPopoverIfNecessary(popoverFrames: popoverFrames, point: point, popoverToDismiss: popover)
        }
        
        print("[PopoverGestureContainer] hitTest event: \(point) did not hit any popover")
        
        /// The touch did not hit any popover, so pass it through to the hit testing target.
        return nil
    }
    
    /// Dismiss a popover, knowing that its frame does not contain the touch.
    func dismissPopoverIfNecessary(popoverFrames: [CGRect], point: CGPoint, popoverToDismiss: Popover) {
        if
            popoverToDismiss.attributes.dismissal.mode.contains(.tapOutside), /// The popover can be automatically dismissed when tapped outside.
            popoverToDismiss.attributes.dismissal.tapOutsideIncludesOtherPopovers || /// The popover can be dismissed even if the touch hit another popover, **or...**
            !popoverFrames.contains(where: { $0.contains(point) }) /// ... no other popover frame contains the point (the touch landed outside)
        {
            popoverToDismiss.dismiss()
        }
    }
    
    private var monitor: Any?
        
    deinit {
        // Clean up click recognizer
        print("[PopupGestureRecognizer] deinit")
        removeCloseOnOutsideClick()
    }
    
    override var isFlipped: Bool {
        return true
//        return false
    }
    
    override var acceptsFirstResponder: Bool {
        return true
    }

    override var mouseDownCanMoveWindow: Bool {
        return true
    }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        print("[PopoverGestureContainer] acceptsFirstMouse event: \(String(describing: event))")
        return true
    }
    
    /**
     Creates a monitor for outside clicks. If clicking outside of this view or
     any views in `ignoringViews`, the view will be hidden.
     */
    func addCloseOnOutsideClick(ignoring ignoringViews: [NSView]? = nil) {
        monitor = NSEvent.addLocalMonitorForEvents(matching: NSEvent.EventTypeMask.leftMouseDown) { (event) -> NSEvent? in
            print("[PopoverGestureContainer] addCloseOnOutsideClick: myFrame: \(self.frame) locationInWindow: \(event.locationInWindow) isHidden: \(self.isHidden)")
            let pointViewLocation = self.convert(event.locationInWindow, from: nil)
            if let view = self.hitTest(pointViewLocation) {
                print("[PopoverGestureContainer] addCloseOnOutsideClick hittest WITH view\n \(view.frame) acceptsFirstResponder: \(view.acceptsFirstResponder)  -- \(view)")
                view.mouseDown(with: event)
                return nil

            } else {
                return event
            }
            
        }
    }
    
    
    func removeCloseOnOutsideClick() {
        if monitor != nil {
            NSEvent.removeMonitor(monitor!)
            monitor = nil
        }
    }

    /// Boilerplate code.
    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("[Popovers] - Create this view programmatically.")
    }
}

class DebugHelper {
    static func printResponderChain(from responder: NSResponder?) {
        var responder = responder
        while let r = responder {
            print(r)
            responder = r.nextResponder
        }
    }
}

#endif
