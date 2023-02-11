//
//  Menu+SwiftUI.swift
//  Popovers
//
//  Created by A. Zheng (github.com/aheze) on 6/14/22.
//  Copyright © 2022 A. Zheng. All rights reserved.
//


import SwiftUI
import SwiftUIKit

public extension Templates {
    /**
     A built-from-scratch version of the system menu.
     */
    @available(iOS 14.0, *)
    struct Menu<Label: View, Content: View>: View {
        /// View model for the menu buttons. Should be `StateObject` to avoid getting recreated by SwiftUI, but this works on iOS 13.
        @StateObject var model: MenuModel

        /// View model for controlling menu gestures.
        @StateObject var gestureModel: MenuGestureModel

        /// Allow presenting from an external view via `$present`.
        @Binding var overridePresent: Bool

        /// The menu buttons.
        public let content: () -> Content

        /// The origin label.
        public let label: (Bool) -> Label

        /// Fade the origin label.
        @State var fadeLabel = false

        
        @State var labelPressed = false
        
        
        
        @GestureState var holdDragState: HoldThenDragGestureState = .inactive
        /**
         A built-from-scratch version of the system menu, for SwiftUI.
         */
        public init(
            present: Binding<Bool> = .constant(false),
            configuration buildConfiguration: @escaping ((inout MenuConfiguration) -> Void) = { _ in },
            @ViewBuilder content: @escaping () -> Content,
            @ViewBuilder label: @escaping (Bool) -> Label
        ) {
            _overridePresent = present
            _model = StateObject(wrappedValue: MenuModel(buildConfiguration: buildConfiguration))
            _gestureModel = StateObject(wrappedValue: MenuGestureModel())
            self.content = content
            self.label = label
        }
        
        
        public var body: some View {
            ScrollViewGestureButton(
                isPressed: $labelPressed,
                releaseInsideAction: {
                    print("releaseInsideAction")
                },
                releaseOutsideAction: {
                    print("releaseOutsideAction")

                },
                longPressDelay: model.configuration.holdDelay,
                longPressAction: {
                    print("longPress")

                },
                doubleTapAction: {
                    print("doubleTap")
                },
                repeatAction: {
                    print("repeatAction")
                },
                dragStartAction: {
                    print("dragStartAction: \($0.location)")

                },
                dragAction: {
                    print("dragAction: \($0.location)")

                },
                dragEndAction: {
                    print("dragEndAction: \($0.location)")
                },
                endAction: {
                    print("endAction: ")

                },
                label: { isPressed in
                    menu
                }
            )
//            menu
        }
        
        
        public var menu: some View {
            label(fadeLabel)
                .contentShape(Rectangle())

                .popover(
                    present: $model.present,
                    attributes: {
                        $0.position = .absolute(
                            originAnchor: model.configuration.originAnchor,
                            popoverAnchor: model.configuration.popoverAnchor
                        )
                        $0.rubberBandingMode = .none
                        $0.dismissal.excludedFrames = {
                            []
                                + model.configuration.excludedFrames()
                        }
                        $0.sourceFrameInset = model.configuration.sourceFrameInset
                        $0.screenEdgePadding = model.configuration.screenEdgePadding
                    }
                ) {
                    MenuView(
                        model: model,
                        content: content
                    )
                } background: {
                    model.configuration.backgroundColor
                }
        }
        
        

        public var oldBody: some View {
            
            
            WindowReader { window in
                let dragGesture = DragGesture(minimumDistance: 10, coordinateSpace: .global)
                
                let combinedGesture = LongPressGesture(minimumDuration: model.configuration.holdDelay)
                    .sequenced(before: dragGesture)
                    .updating($holdDragState) { value, state, transaction in
                        switch value {
                        //long press begins
                        case .first(true):
                            state = .pressing
                            gestureModel.labelPressUUID = UUID()
                        // Long press confirmed, dragging may begin.
                        case .second(true, let drag):
                            #if os(iOS)
                            if model.configuration.hapticFeedbackEnabled {
                                let feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
                                feedbackGenerator.prepare()
                                feedbackGenerator.impactOccurred()
                            }
                            #endif
                            withAnimation(model.configuration.labelFadeAnimation) {
                                fadeLabel = true
                            }
                            if !model.present {
                                model.present = true
                            }
                            state = .dragging(translation: drag?.translation ?? .zero)
                            if let dragExp = drag {
                                gestureModel.onDragChanged(
                                    newDragLocation: dragExp.location,
                                    model: model,
                                    labelFrame: window.frameTagged(model.id),
                                    window: window
                                ) { present in
                                    model.present = present
                                } fadeLabel: { fade in
                                    fadeLabel = fade
                                }
                            }
                            
                        default:
                            //dragging ended or long press cancelled
                            state = .inactive
                        }
                    }
                    .onEnded { value in
                        guard case .second(true, let drag?) = value else { return }
                        gestureModel.onDragEnded(
                            newDragLocation: drag.location,
                            model: model,
                            labelFrame: window.frameTagged(model.id),
                            window: window
                        ) { present in
                            model.present = present
                        } fadeLabel: { fade in
                            fadeLabel = fade
                        }
                        
                    }
                
                label(fadeLabel)
                    .frameTag(model.id)
                    .contentShape(Rectangle())
                    .simultaneousGesture(TapGesture()
                        .onEnded {
                            if model.present {
                                model.present = false
                            }
                        }
                    )
                    .simultaneousGesture(combinedGesture)

                    .onValueChange(of: model.present) { _, present in
                        if !present {
                            withAnimation(model.configuration.labelFadeAnimation) {
                                fadeLabel = false
                                model.selectedItemID = nil
                                model.hoveringItemID = nil
                            }
                            overridePresent = present
                        }
                    }
                    .onValueChange(of: overridePresent) { _, present in
                        if present != model.present {
                            model.present = present
                            withAnimation(model.configuration.labelFadeAnimation) {
                                fadeLabel = present
                            }
                        }
                    }
                    .popover(
                        present: $model.present,
                        attributes: {
                            $0.position = .absolute(
                                originAnchor: model.configuration.originAnchor,
                                popoverAnchor: model.configuration.popoverAnchor
                            )
                            $0.rubberBandingMode = .none
                            $0.dismissal.excludedFrames = {
                                [
                                    window.frameTagged(model.id),
                                ]
                                    + model.configuration.excludedFrames()
                            }
                            $0.sourceFrameInset = model.configuration.sourceFrameInset
                            $0.screenEdgePadding = model.configuration.screenEdgePadding
                        }
                    ) {
                        MenuView(
                            model: model,
                            content: content
                        )
                    } background: {
                        model.configuration.backgroundColor
                    }
            }
        }
    }
}


enum HoldThenDragGestureState {
    case inactive
    case pressing
    case dragging(translation: CGSize)
}

