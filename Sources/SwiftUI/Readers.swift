//
//  Readers.swift
//  Popovers
//
//  Created by A. Zheng (github.com/aheze) on 12/23/21.
//  Copyright © 2022 A. Zheng. All rights reserved.
//

import SwiftUI

/**
 Read the popover's context from within its `view` or `background`.
 Use this just like `GeometryReader`.

  **Warning:** This must be placed inside a popover's `view` or `background`.
 */
public struct PopoverReader<Content: View>: View {
    /// Read the popover's context from within its `view` or `background`.
    public init(@ViewBuilder view: @escaping (Popover.Context) -> Content) {
        self.view = view
    }

    /// The parent view.
    @ViewBuilder var view: (Popover.Context) -> Content

    /// The popover's context (passed down from `Popover.swift`).
    @EnvironmentObject var context: Popover.Context

    public var body: some View {
        /// Pass the context down.
        view(context)
    }
}


/**
 Read the current `UIWindow` that hosts the view.
 Use this just like `GeometryReader`.

  **Warning:** Do *not* place this inside a popover's `view` or its `background`.
  Instead, use the `window` property of the popover's context.
 */
public struct WindowReader<Content: View>: View {
    /// Your SwiftUI view.
    public let view: (UniversalWindow?) -> Content

    /// The read window.
    @StateObject var windowViewModel = WindowViewModel()

    /// Reads the `UIWindow` that hosts some SwiftUI content.
    public init(@ViewBuilder view: @escaping (UniversalWindow?) -> Content) {
        self.view = view
    }

    public var body: some View {
        view(windowViewModel.window)
//            .id(windowViewModel.window)
            .background(
                WindowHandlerRepresentable(windowViewModel: windowViewModel)
            )
        
    }

    /// A wrapper view to read the parent window.
    private struct WindowHandlerRepresentable: PlatformAgnosticViewRepresentable {
        @ObservedObject var windowViewModel: WindowViewModel

        func makePlatformView(context _: Context) -> WindowHandler {
            return WindowHandler(windowViewModel: self.windowViewModel)
        }

        func updatePlatformView(_: WindowHandler, context _: Context) {}
    }

    private class WindowHandler: PlatformView {
        var windowViewModel: WindowViewModel
        
        var settingWindowInProgress: Bool = false
        
        init(windowViewModel: WindowViewModel) {
            self.windowViewModel = windowViewModel
            super.init(frame: .zero)
            self.setBackgroundClear()
        }

        @available(*, unavailable)
        required init?(coder _: NSCoder) {
            fatalError("[Popovers] - Create this view programmatically.")
        }

        #if os(iOS)
        override func didMoveToWindow() {
            print("[Popover] Readers WindowHandler didMoveToWindow")
            super.didMoveToWindow()
            
            
            DispatchQueue.main.async {
                /// Set the window.
                self.windowViewModel.window = self.window
            }
            
//            if !self.settingWindowInProgress {
//                self.settingWindowInProgress = true
//                DispatchQueue.main.async {
//                    /// Set the window.
//                    self.windowViewModel.window = self.window
//                    print("[Popover] Readers WindowHandler didMoveToWindow set windowViewModel")
//                    self.settingWindowInProgress = false
//                }
//            }
        }
        #elseif os(macOS)
        override func viewDidMoveToWindow() {
//            print("[Popover] Readers WindowHandler viewDidMoveToWindow")
                        
            super.viewDidMoveToWindow()
//            DispatchQueue.main.async {
//                
//                if !self.settingWindowInProgress {
//                    self.settingWindowInProgress = true
//                    self.windowViewModel.window = self.window
//                    print("[Popover] Readers WindowHandler viewDidMoveToWindow set windowViewModel")
//                    self.settingWindowInProgress = false
//                }
//                
//            }
            
            
        }
        #endif
        
    }
}


class WindowViewModel: ObservableObject {
    @Published var window: UniversalWindow?
}

