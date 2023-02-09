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

        /// Create the SwiftUI view that contains all the popovers.
        let popoverContainerView = PopoverContainerView(popoverModel: popoverModel)
            .environment(\.window, window) /// Inject the window.

        let hostingController = NSHostingController(rootView: popoverContainerView)
        hostingController.view.frame = bounds
        hostingController.view.wantsLayer = true
        hostingController.view.layer?.backgroundColor = .clear

        addSubview(hostingController.view)

        /// Ensure the view is laid out so that SwiftUI animations don't stutter.
        resizeSubviews(withOldSize: self.frame.size)
        layoutSubtreeIfNeeded()

        /// Let the presenter know that its window is available.
        onMovedToWindow?()
    }
    

    
    public override func mouseDown(with event: NSEvent) {
        // Translate the event location to view coordinates
        let convertedLocation = self.convertFromBacking(event.locationInWindow)

        if let viewBelow = self
            .superview?
            .subviews // Find next view below self
            .lazy
            .compactMap({ $0.hitTest(convertedLocation) })
            .first
        {
            self.window?.makeFirstResponder(viewBelow)
        }

        super.mouseDown(with: event)
    }
    
    public override func hitTest(_ point: NSPoint) -> NSView? {
        
        /// Only loop through the popovers that are in this window.
        let popovers = popoverModel.popovers

        /// The current popovers' frames
        let popoverFrames = popovers.map { $0.context.frame }
        
        /// Loop through the popovers and see if the touch hit it.
        /// `reversed` to start from the most recently presented popovers, working backwards.
        for popover in popovers.reversed() {
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
    
    

    /// Boilerplate code.
    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("[Popovers] - Create this view programmatically.")
    }
}
#endif
