//
//  CommentsViewModel.swift
//  MVVM-RxSwift-Test
//

import Foundation
import RxSwift
import RxCocoa

final class CommentsViewModel {
   let commentsService:CommentsServiceType
   var coordinator:PostNavigation?
   
   var comments:Driver<[Comment]> {
      return commentsService.comments.asDriver(onErrorJustReturn:[Comment]())
   }
   
   init(commentsService:CommentsServiceType, coordinator:PostNavigation? = nil) {
      self.commentsService = commentsService
      self.coordinator = coordinator
   }
   
   func fetchComments(for postId:Int) {//}-> Observable<[Comment]> {
      commentsService.fetchComments(for: postId)
   }
}
