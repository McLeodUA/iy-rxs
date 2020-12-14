//
//  DocumentsFolderReader.swift
//  PostsTestMVC
//

import Foundation
import RxSwift

enum DataType {
   case user
   case posts
   case comments
}

class DocumentsFolderReader {
   
   private let entityRead = PublishSubject<Decodable>()
   
   var neededEntity: Observable<Decodable> {
      return entityRead.asObservable()
   }
   
   func readDataFromDocuments(for dataType:DataType, at url: URL) { //} -> T? {
      
      guard FileManager.default.fileExists(atPath: url.path) else {
         entityRead.onError(FileError.notExists(message: "file does not exist"))
         return
      }
      
      var result:Decodable?
      var error:Error?
      
      do {
         let data = try Data(contentsOf: url)
         let decoder = JSONDecoder()
         
         switch dataType {
         case .posts:
            let posts = try decoder.decode([Post].self, from: data)
            result = posts.isEmpty ? nil : posts
         case .user:
            let user = try decoder.decode(User.self, from: data)
            result = user
         case .comments:
            let comments = try decoder.decode([Comment].self, from: data)
            result = comments.isEmpty ? nil : comments
         }
      }
      catch (let dataReadingError) {
         #if DEBUG
         print("DocumentsFolderReader -> ERROR decoding \(dataType) from file: \(dataReadingError.localizedDescription)")
         #endif
         error = dataReadingError
      }
      
      if let rightResult = result {
         entityRead.onNext(rightResult) //success
      }
      else {
         if let anError = error {
            entityRead.onError(anError)
         }
         else {
            entityRead.onError(FileError.failedToConvert)
         }
      }
   }
}
