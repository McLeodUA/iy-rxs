//
//  StoragePaths.swift
//  PostsTestMVC
//

import Foundation

let baseURLString = "http://jsonplaceholder.typicode.com"

enum DocumentsURL {
   case posts
   case comments(Int)
   case user(Int)
}


func urlFor(_ docUrl:DocumentsURL) -> URL? {
   
   var result:URL?
   //primitive file names for test project
   switch docUrl {
      case .posts:
         result = documentsURL()?.appendingPathComponent("Posts.bin")
      case .comments(let postId):
         result = documentsURL()?.appendingPathComponent("Comments-\(postId).bin")
      case .user(let userId):
         result = documentsURL()?.appendingPathComponent("User-\(userId).bin")
   }
   
   return result
}

fileprivate func documentsURL() -> URL? {
   var docsUrl:URL?
   
   let fileMan = FileManager.default
   
   guard let aUrl = fileMan.urls(for: .documentDirectory,
                                 in: FileManager.SearchPathDomainMask.userDomainMask).first else {
                                    return nil
   }
   
   docsUrl = aUrl
   return docsUrl
}
