//
//  PostViewModel.swift
//  MVVM-RxSwift-Test
//

import Foundation

struct PostViewModel {
   
   private let post:Post
   
   var titleText:String {
      return post.title
   }
   
   var detailsText:String {
      return post.body
   }
   
   init(post:Post) {
      self.post = post
   }
}
