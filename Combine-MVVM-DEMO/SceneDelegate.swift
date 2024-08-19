//
//  SceneDelegate.swift
//  Combine-MVVM-DEMO
//
//  Created by Gucci on 8/18/24.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        self.window = UIWindow(windowScene: windowScene)
        let vc = QuoteViewController()
        self.window?.rootViewController = vc
        self.window?.makeKeyAndVisible()
    }
}

