//
//  AppCoordinator.swift
//  MVVM-RxSwift-Test
//

import Foundation
import UIKit

protocol PostNavigation : class {
   func navigateToPost(_ post:Post)
}

class AppCoordinator {
   
   private let window:UIWindow
   
   init(window:UIWindow) {
      self.window = window
   }
   
   func start() {
      
      guard let postsListScreen =
               PostsListScreenViewController.create(viewModel:
                                                      PostsListViewModel(postsService: PostsService(),
                                                                         postNavigator: self)) else {
         return
      }
      
      let navigationController = UINavigationController(rootViewController: postsListScreen)
      
      window.rootViewController = navigationController
      window.makeKeyAndVisible()
   }
   
   private func showPostDetailsScreen(post:Post) {
      guard let navController = window.rootViewController as? UINavigationController else {
         return
      }
      
      let postDetailsScreen = PostDetailsScreenViewController.createWithPost(post, coordinator: self)
      //postDetailsScreen.edgesForExtendedLayout = []
      navController.pushViewController(postDetailsScreen, animated: true)
   }
   
}

extension AppCoordinator : PostNavigation {
   func navigateToPost(_ post: Post) {
      showPostDetailsScreen(post:post)
   }
   
   func goToPostsListScreen() {
      (window.rootViewController as? UINavigationController)?.popToRootViewController(animated: true)
   }
}
