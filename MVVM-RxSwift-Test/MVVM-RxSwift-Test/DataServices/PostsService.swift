//
//  PostsService.swift
//  MVVM-RxSwift-Test
//

import Foundation
import RxSwift
import RxCocoa

protocol PostsServiceType {
   func fetchPosts() -> Observable<[Post]>
}

class PostsService: PostsServiceType {
   
   private let bag = DisposeBag()
   private let postsRelay = BehaviorRelay<[Post]>(value:[])
   private var postsResponse: Observable<[Post]>?
   
   private lazy var docsumentsFolderReader:DocumentsFolderReader = DocumentsFolderReader()
   
   func fetchPosts() -> Observable<[Post]> {
      
      subscribeOnReadFromDocuments()
      
      guard let postsURL = urlFor(.posts) else {
         print("ERROR creating POSTs file URL")
         
         return postsRelay.asObservable()
      }
      
      DispatchQueue(label: "ReaddPosts.background.queue").async { [unowned self] in
         docsumentsFolderReader.readDataFromDocuments(for: .posts, at: postsURL)
      }
    
      return postsRelay.asObservable()
   }
   
   private func subscribeOnReadFromDocuments() {
      docsumentsFolderReader =
      DocumentsFolderReader()
         
      docsumentsFolderReader
         .neededEntity
         .subscribe(on:SerialDispatchQueueScheduler(qos: .default))
         .observe(on:MainScheduler.instance)
         .subscribe {[weak self] (decodable) in
            
            if let posts = decodable as? [Post] {
               self?.postsRelay.accept(posts)
            }
            
      } onError: {[weak self] (error) in
         print("File POSTS reading error: \(error)")
         
         if let fileError = error as? FileError {
         
            switch fileError {
            case .failedToConvert:
               print("Unknown error while converting POSTs from disk")
            case .notExists(let message):
               if let errorMessage = message {
                  print(#function + " error message received: \(errorMessage)")
               }
               //make a netwotk request and try save to Disk later
               self?.tryToLoadPosts()
            }
         }
      } onCompleted: {
         print("File POSTS reading completed")
      } onDisposed: {
         print("File POSTS reading disposed")
      }
      .disposed(by: bag)
   }
   
   private func createNetworkObservable() -> Observable<[Post]>? {
      
      //create network request subscription if no data is on the disk
      guard let postsUrl = URL(string: "http://jsonplaceholder.typicode.com/posts") else {
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
         .map {  _ , data -> [Post] in
            do {
               let posts = try JSONDecoder().decode([Post].self, from: data)
               
               if let postsURL = urlFor(.posts) {
                  DocumentsFolderWriter.writeEntity(posts, toURL:postsURL)
               }
                
               return posts
            }
            catch (let decodeError) {
               print("response on POSTS - decoding error: \(decodeError.localizedDescription)")
               return []
            }
         }
         .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .default))
         .observe(on: MainScheduler.instance)

      return downloadObservable
      
//      //create an observable - option 2 (less debug console output)
//      let downloadObservable:Observable<[Post]> = Observable.create { (observer) -> Disposable in
//
//         let task = URLSession.shared.dataTask(with: request) { (postsData, response, postsError) in
//
//
//            if let error = postsError {
//               observer.onError(error)
//            }
//            else if let httpResp = response as? HTTPURLResponse {
//               if httpResp.statusCode >= 200 && httpResp.statusCode < 300 {
//                  guard let data = postsData, !data.isEmpty else {
//                     //TODO: Return valid error
//                     return
//                  }
//
//                  do {
//                     let posts = try JSONDecoder().decode([Post].self, from: data)
//                     observer.onNext(posts) //success loading posts and returning
//                  }
//                  catch (let decodeError) {
//                     print("Posts Decoder Error: \(decodeError.localizedDescription)")
//                     //TODO: Return valid error
//                  }
//               }
//               else {
//                  // TODO: Return valid error
//               }
//            }
//         }
//
//         task.resume()
//
//         return Disposables.create {
//            task.cancel()
//         }
//      }
//      .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .default))
//      .observe(on: MainScheduler.instance)
//
//      return downloadObservable
   }
   
   private func tryToLoadPosts() {
      postsResponse = createNetworkObservable()
      
      postsResponse?.subscribe(onNext: {[weak self] (posts) in
         self?.postsRelay.accept(posts)
      })
      .disposed(by: bag)
   }
}
