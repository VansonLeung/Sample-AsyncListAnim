//
//  AppRootNavigationViewLinkBundle.swift
//  hkstp oneapp testing
//
//  Created by Leung Yu Wing on 23/4/2022.
//

import Foundation
import SwiftUI


class AppRootNavigationViewLinkBundleActivityObs: ObservableObject {
    private static var sharedInstance : AppRootNavigationViewLinkBundleActivityObs?
    static var shared : AppRootNavigationViewLinkBundleActivityObs {
        if sharedInstance == nil {
            sharedInstance = AppRootNavigationViewLinkBundleActivityObs()
        }
        return sharedInstance!
    }
    
    
    @Published var activeLinkBundle : AppRootNavigationViewLinkBundleObs?
}


class AppRootNavigationViewLinkBundleObs: ObservableObject {
    public let id = UUID()
    
    @Published var isActive_AnyView: Bool = false
    @Published var isActive_AnyView_view: AnyView?
    @Published var isActive_AnyView_Animated: Bool = true

    @Published var isActive_AnyView2: Bool = false
    @Published var isActive_AnyView_view2: AnyView?
    @Published var isActive_AnyView2_Animated: Bool = true

    func openAnyView(item: AnyView) {
        openAnyView(item: item, animated: true)
    }
    
    func openAnyView(item: AnyView, animated: Bool) {
        if isActive_AnyView
        {
            isActive_AnyView2 = true
            isActive_AnyView_view2 = item
            isActive_AnyView2_Animated = animated
        }
        else
        {
            isActive_AnyView_Animated = animated
            _run(item: item)
        }
    }
    
    func closeView() {
        isActive_AnyView_view2 = nil
        isActive_AnyView_view = nil
        isActive_AnyView2 = false
        isActive_AnyView = false
    }
    
    private func _run(item: AnyView)
    {
        if isActive_AnyView_Animated
        {
            isActive_AnyView = true
            isActive_AnyView_view = item
        }
        else
        {
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                isActive_AnyView = true
                isActive_AnyView_view = item
            }
        }
    }
    
    
    
    func openPendingView() {
        if isActive_AnyView2, let view = isActive_AnyView_view2
        {
            isActive_AnyView2 = false
            isActive_AnyView_Animated = isActive_AnyView2_Animated
            _run(item: view)
            isActive_AnyView_view2 = nil
        }
    }
    
    
}






struct AppRootNavigationViewLinkBundle: View {
    @ObservedObject var linkBundleObs : AppRootNavigationViewLinkBundleObs
    
    var body: some View {
        ZStack {
            NavigationLink(destination: linkBundleObs.isActive_AnyView_view,
                           isActive: $linkBundleObs.isActive_AnyView) {
                EmptyView()
            }
            .buttonStyle(NoTapEffectButtonStyle())
        }
        .onReceive(linkBundleObs.$isActive_AnyView) { output in
            if output == false {
                if linkBundleObs.isActive_AnyView2 == true
                {
                    DispatchQueue.main.async {
                        linkBundleObs.openPendingView()
                    }
                }
            }
        }
    }
}





struct AppRootNavPageAsDetailsView: ViewModifier {
    @ObservedObject var __appRootNavigationViewLinkBundleObs : AppRootNavigationViewLinkBundleObs
    func body(content: Content) -> some View {
        ZStack {
            AppRootNavigationViewLinkBundle(linkBundleObs: __appRootNavigationViewLinkBundleObs)
            content
        }
        
        .onAppear {
            AppRootNavigationViewLinkBundleActivityObs.shared.activeLinkBundle = __appRootNavigationViewLinkBundleObs
        }
        .onDisappear {
//            if let b = AppRootNavigationViewLinkBundleActivityObs.shared.activeLinkBundle,
//               b.id == __appRootNavigationViewLinkBundleObs.id
//            {
//                AppRootNavigationViewLinkBundleActivityObs.shared.activeLinkBundle = nil
//            }
        }
    }
}


extension View {
    
    func asDetailsView(
        linkBundleObs : AppRootNavigationViewLinkBundleObs
    ) -> some View {
        self
            .modifier(
                AppRootNavPageAsDetailsView(__appRootNavigationViewLinkBundleObs: linkBundleObs)
            )
            .interactivePopGestureRecognizerDisabled(false)
    }
 
    func interactivePopGestureRecognizerDisabled(_ isDisabled: Bool?) -> some View {
        UIApplication.setInteractivePopGestureRecognizerDisabled(isDisabled)
        return self
            .onAppear {
                UIApplication.setInteractivePopGestureRecognizerDisabled(isDisabled)
            }
    }

}



class HostingController<Content: View>: UIHostingController<Content> {
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIApplication.statusBarStyle
    }
}


extension UIApplication {
    static var hostingController: HostingController<AnyView>? = nil
    
    static var statusBarStyleHierarchy: [UIStatusBarStyle] = []
    static var statusBarStyle: UIStatusBarStyle = .darkContent
    
    static var interactivePopGestureRecognizerDisabled: Bool = false
    
    ///Sets the App to start at rootView
    func setHostingController(rootView: AnyView) {
        let hostingController = HostingController(rootView: AnyView(rootView))
        windows.first?.rootViewController = hostingController
        UIApplication.hostingController = hostingController
    }
    
    static func setStatusBarStyle(_ style: UIStatusBarStyle) {
        statusBarStyle = style
        hostingController?.setNeedsStatusBarAppearanceUpdate()
    }
    
    static func setInteractivePopGestureRecognizerDisabled(_ isDisabled: Bool?) {
        interactivePopGestureRecognizerDisabled = isDisabled ?? false
    }
}



public extension View {
    
    /// Helper to create `AnyView` from view
    var anyView: AnyView {
        AnyView(self)
    }
}



struct NoTapEffectButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
    }
}
