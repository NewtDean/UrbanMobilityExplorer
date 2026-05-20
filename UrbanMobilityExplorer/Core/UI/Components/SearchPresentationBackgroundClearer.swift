//
//  SearchPresentationBackgroundClearer.swift
//  Urban Mobility Explorer
//
//  Created by Newt Ding on 2026/05/19.
//
//  Copyright © 2026 The Hongkong and Shanghai Banking Corporation Limited. All rights reserved.
//

import SwiftUI
import UIKit

/// Clears the UITableView / scroll host UIKit paints behind `.searchable` + `NavigationStack` content.
struct SearchPresentationBackgroundClearer: UIViewRepresentable {
    var isActive: Bool

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.isUserInteractionEnabled = false
        view.backgroundColor = .clear
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        guard isActive else { return }
        DispatchQueue.main.async {
            clearSearchHostBackgrounds(startingAt: uiView)
        }
    }

    private func clearSearchHostBackgrounds(startingAt view: UIView) {
        if let navigationRoot = view.enclosingNavigationController?.view {
            clearScrollHosts(in: navigationRoot)
        }
        clearScrollHosts(in: view)
    }

    private func clearScrollHosts(in view: UIView) {
        if let table = view as? UITableView {
            table.backgroundColor = .clear
            table.backgroundView = nil
            table.separatorStyle = .none
        } else if let scroll = view as? UIScrollView {
            scroll.backgroundColor = .clear
        }
        view.subviews.forEach { clearScrollHosts(in: $0) }
    }
}

private extension UIView {
    var enclosingNavigationController: UINavigationController? {
        var responder: UIResponder? = self
        while let current = responder {
            if let navigation = current as? UINavigationController {
                return navigation
            }
            if let controller = current as? UIViewController,
               let navigation = controller.navigationController {
                return navigation
            }
            responder = current.next
        }
        return nil
    }
}

extension View {
    /// Use on content inside a `NavigationStack` that uses `.searchable` when the sheet should stay visually clear.
    func clearSearchPresentationBackground(when isActive: Bool) -> some View {
        background {
            SearchPresentationBackgroundClearer(isActive: isActive)
        }
    }
}
