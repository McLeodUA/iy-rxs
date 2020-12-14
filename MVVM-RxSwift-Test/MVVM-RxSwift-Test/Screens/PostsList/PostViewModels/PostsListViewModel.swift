//
//  PostsListViewModel.swift
//  MVVM-RxSwift-Test
//

import Foundation
import RxSwift
import RxCocoa
import UIKit

final class PostsListViewModel {
   
   private var bag = DisposeBag()
   
   var selectedPost = PublishRelay<Post>()
   
   let title = "Posts"
   
   weak var navigator:PostNavigation?
   
   var posts = [Post]()
   
   let postsService:PostsServiceType
   
   init(postsService:PostsServiceType = PostsService(), postNavigator:PostNavigation? = nil) {
      self.postsService = postsService
      navigator = postNavigator
      
      selectedPost.subscribe {[weak self] (aPost) in
         self?.navigator?.navigateToPost(aPost)
      }.disposed(by: bag)
   }
   
   func fetchPostViewModels() -> Observable<[PostViewModel]> {
      postsService.fetchPosts().map {
         self.posts = $0
         return $0.map { PostViewModel(post: $0) }
      }
   }
   
   func selectPostAt(_ postIndex:Int) {
      if postIndex >= 0 && postIndex < posts.count {
         selectedPost.accept(posts[postIndex])
      }
   }
}
