//
//  UsersService.swift
//  MVVM-RxSwift-Test
//

import Foundation
import RxSwift
import RxCocoa

class UsersService {
   
   private let bag = DisposeBag()
   private let userRelay = BehaviorRelay<User>(value: User.defaultEmptyUser())
   private lazy var dosumentsFolderReader = DocumentsFolderReader()
   private var userRequestObservable:Observable<User>?
   
   //MARK: -
   
   var fetchedUser:Observable<User> {
      return userRelay.asObservable()
   }
   
   func fetshUser(withId userId:Int) -> Bool {
      
      
      
      let docsReadingQueue = DispatchQueue.init(label: "UserReading",
                                                qos: .default,
                                                attributes: [],
                                                autoreleaseFrequency: DispatchQueue.AutoreleaseFrequency.workItem,
                                                target: nil)
      
      guard let commentsDocsURL = urlFor(.user(userId)) else {
         print("ERROR creating USER`s file URL")
         
         return false
      }
      
      subscribeOnReadFromDocuments(for: userId)
      
      docsReadingQueue.async {[unowned self] in
         dosumentsFolderReader.readDataFromDocuments(for: .user, at: commentsDocsURL)
      }
      
      return true
   }
   
   //MARK: -
   private func subscribeOnUserLoad(for userId:Int) {
      userRequestObservable = createNetworkObservableUser(for: userId)
      
      userRequestObservable?.subscribe(onNext: {[weak self] (comments) in
         self?.userRelay.accept(comments)
      }, onError: { (loadError) in
         print("USER Loading for USER '\(userId)' ERROR: \n\(loadError.localizedDescription)")
      }, onCompleted: {
         print("USER Loading for USER '\(userId)' completed")
      }, onDisposed: {
         print("USER Loading for USER '\(userId)' disposed")
      }).disposed(by: bag)
   }
   
   private func subscribeOnReadFromDocuments(for userId:Int) {
      let _ =
      dosumentsFolderReader.neededEntity
         .subscribe(on:SerialDispatchQueueScheduler(qos: .default))
         .observe(on:MainScheduler.instance)
         .subscribe {[weak self] (decodable) in

            if let user = decodable as? User {
               self?.userRelay.accept(user)
            }
            
      } onError: {[weak self] (error) in
         print("File USER reading error: \(error)")
         
         if let fileError = error as? FileError {
         
            switch fileError {
            case .failedToConvert:
               print("Unknown error while converting USER from disk")
            case .notExists(let message):
               if let errorMessage = message {
                  print(#function + " error message received: \(errorMessage)")
               }
               //make a netwotk request and try save to Disk later
               self?.subscribeOnUserLoad(for: userId)
            }
         }
      } onCompleted: {
         print("File POSTS reading completed")
      } onDisposed: {
         print("File POSTS reading disposed")
      }
         .disposed(by: bag)
   }
   
   
   private func createNetworkObservableUser(for userId:Int) -> Observable<User>? {
      //create network request subscription if no data is on the disk
      
      
      let userIdParameter = URLQueryItem(name: "id", value: String(userId))
      
      var components = URLComponents()
      components.scheme = "http"
      components.host = "jsonplaceholder.typicode.com"
      components.path = "/users"
      components.queryItems = [userIdParameter]
      
      guard let userURL = components.url else {
         return nil
      }
      
      var request = URLRequest(url: userURL)
      request.setValue("application/json", forHTTPHeaderField: "ACCEPT")
      
      //create an observable - option 1 (more console debug output)
      let downloadObservable = Observable.from(optional: userURL)
         .map { (url) -> URLRequest in
            var request = URLRequest(url: userURL)
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
         .map {  _ , data -> User in
            do {
               
               let aUser = try JSONDecoder().decode([User].self, from: data).first
               
               guard let realUser = aUser else {
                  return User.defaultEmptyUser()
               }
               
               if let userURL = urlFor(.user(userId)) {
                  DocumentsFolderWriter.writeEntity(realUser, toURL:userURL)
               }
                
               return realUser
            }
            catch (let decodeError) {
               print("response on USER - decoding error: \(decodeError.localizedDescription)")
               return User.defaultEmptyUser()
            }
         }
         .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .default))
         .observe(on: MainScheduler.instance)

      return downloadObservable
   }
}
