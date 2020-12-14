//
//  CommentsService.swift
//  MVVM-RxSwift-Test
//

import Foundation
import RxSwift
import RxCocoa

protocol CommentsServiceType {
   var comments:Observable<[Comment]> {get}
   func fetchComments(for postId:Int)
}

class CommentsService: CommentsServiceType {
   
   private let bag = DisposeBag()
   private lazy var dosumentsFolderReader = DocumentsFolderReader()
   
   private let commentsRelay = BehaviorRelay<[Comment]>(value:[])
   
   var comments:Observable<[Comment]> {
      return commentsRelay.asObservable()
   }
   
   private var commentsRequestObservable:Observable<[Comment]>?
   
   func fetchComments(for postId: Int) {
      
      let docsReadingQueue = DispatchQueue.init(label: "CommentsReading",
                                                qos: .default,
                                                attributes: [],
                                                autoreleaseFrequency: DispatchQueue.AutoreleaseFrequency.workItem,
                                                target: nil)
      
      guard let commentsDocsURL = urlFor(.comments(postId)) else {
         print("ERROR creating COMMENTS` file URL")
         
         return
      }
      
      subscribeOnReadFromDocuments(for: postId)
      
      docsReadingQueue.async {[unowned self] in
         dosumentsFolderReader.readDataFromDocuments(for: .comments, at: commentsDocsURL)
      }
      
   }
   
   private func createNetworkObservableComments(for postId:Int) -> Observable<[Comment]>? {
      //create network request subscription if no data is on the disk
      
      
      let postIdParameter = URLQueryItem(name: "postId", value: String(postId))
      
      var components = URLComponents()
      components.scheme = "http"
      components.host = "jsonplaceholder.typicode.com"
      components.path = "/comments"
      components.queryItems = [postIdParameter]
      
      guard let postsUrl = components.url else {
         return nil
      }
      
      var request = URLRequest(url: postsUrl)
      request.setValue("application/json", forHTTPHeaderField: "ACCEPT")
      
      //create an observable - option 1 (more console debug output)
      let downloadObservable = Observable.from(optional: postsUrl)
         .map { (url) -> URLRequest in
            var request = URLRequest(url: postsUrl)
            request.setValue("application/json", forHTTPHeaderField: "ACCEPT")
            return request
         }
         .flatMap { (request) in
            return URLSession.shared.rx.response(request: request)
         }
         .share(replay: 1, scope: SubjectLifetimeScope.whileConnected)
         .filter { response, _ in
            return 200..<300 ~= response.statusCode
         }
         .map {  _ , data -> [Comment] in
            do {
               let comments = try JSONDecoder().decode([Comment].self, from: data)
               
               if let postsURL = urlFor(.comments(postId)) {
                  DocumentsFolderWriter.writeEntity(comments, toURL:postsURL)
               }
                
               return comments
            }
            catch (let decodeError) {
               print("response on POSTS - decoding error: \(decodeError.localizedDescription)")
               return []
            }
         }
         .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .default))
         .observe(on: MainScheduler.instance)

      return downloadObservable
   }
   
   private func subscribeOnCommentsLoad(for postId:Int) {
      commentsRequestObservable = createNetworkObservableComments(for: postId)
      
      commentsRequestObservable?.subscribe(onNext: {[weak self] (comments) in
         self?.commentsRelay.accept(comments)
      }, onError: { (loadError) in
         print("Comments Loading for POST '\(postId)' ERROR: \n\(loadError.localizedDescription)")
      }, onCompleted: {
         print("Comments Loading for POST '\(postId)' completed")
      }, onDisposed: {
         print("Comments Loading for POST '\(postId)' disposed")
      }).disposed(by: bag)
   }
   
   
   private func subscribeOnReadFromDocuments(for postId:Int) {
      let _ =
      dosumentsFolderReader.neededEntity
         .subscribe(on:SerialDispatchQueueScheduler(qos: .default))
         .observe(on:MainScheduler.instance)
         .subscribe {[weak self] (decodable) in
            
            if let comments = decodable as? [Comment] {
               self?.commentsRelay.accept(comments)
            }
            
      } onError: {[weak self] (error) in
         print("File COMMENTS reading error: \(error)")
         
         if let fileError = error as? FileError {
         
            switch fileError {
            case .failedToConvert:
               print("Unknown error while converting POSTs from disk")
            case .notExists(let message):
               if let errorMessage = message {
                  print(#function + " error message received: \(errorMessage)")
               }
               //make a netwotk request and try save to Disk later
               self?.subscribeOnCommentsLoad(for: postId)
            }
         }
      } onCompleted: {
         print("File COMMENTS reading completed")
      } onDisposed: {
         print("File COMMENTS reading disposed")
      }
         .disposed(by: bag)
   }

}
