//
//  PostDetailsScreenViewController.swift
//  MVVM-RxSwift-Test
//

import UIKit
import RxSwift
import RxCocoa

class PostDetailsScreenViewController: UIViewController {

   let bag = DisposeBag()
   
   private var post:Post? {
      didSet {
         if let realPost = post {
            postViewModel = PostViewModel(post: realPost)
         }
      }
   }
   
   private var postViewModel:PostViewModel?
   
   private var commentsViewModel:CommentsViewModel!
   private lazy var userViewModel:UserViewModel = UserViewModel()
   
   @IBOutlet private weak var ibPostTitleLabel:UILabel?
   @IBOutlet private weak var ibPostAuthorLabel:UILabel?
   @IBOutlet private weak var ibPostTextLabel:UILabel?
   @IBOutlet private weak var ibCommentsTable:UITableView?
   
   class func createWithPost(_ post:Post, coordinator:PostNavigation) -> PostDetailsScreenViewController {
      let instance = PostDetailsScreenViewController.init(nibName: "PostDetailsScreenViewController", bundle: nil)
      instance.post = post
      instance.commentsViewModel = CommentsViewModel(commentsService: CommentsService(), coordinator: coordinator)
      return instance
   }
   
   override func viewDidLoad() {
      super.viewDidLoad()
      
      navigationController?.navigationBar.prefersLargeTitles = false
      
      ibCommentsTable?.register(UINib(nibName: "CommentViewCell", bundle: nil), forCellReuseIdentifier: CommentViewCell.reuseIdentifier)
      
      //fast answer to deselect cell on selection
      ibCommentsTable?.rx
         .setDelegate(self)
         .disposed(by: bag)
      
      // Do any additional setup after loading the view.
      guard let aPost = post, let table = ibCommentsTable else {
         return
      }
      
      commentsViewModel.comments
         .asObservable()
         .bind(to: table.rx.items(cellIdentifier: CommentViewCell.reuseIdentifier,
                                  cellType: CommentViewCell.self)) {_ , comment, cell in
            var state = cell.defaultContentConfiguration()
            
            state.text = comment.body
            
            state.secondaryText = comment.name
            
            cell.contentConfiguration = state
      }.disposed(by: bag)

      commentsViewModel.fetchComments(for: aPost.id)
      
      
      //Non-reactive
      ibPostTitleLabel?.text = aPost.title
      ibPostTextLabel?.text = aPost.body
      //
      
      
      // Bind post author label to downloaded post author
      userViewModel.user.asObservable().map { (aUser) -> String in
         return aUser.username
      }
      .bind(to: ibPostAuthorLabel!.rx.text)
      .disposed(by: bag)
      
      let willFetchUser =  userViewModel.fetchUser(with: aPost.userID)
         
      if !willFetchUser {
         print("Error subscribing to USER fetch.")
      }
   }
   
}

extension PostDetailsScreenViewController : UITableViewDelegate {
   func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
      tableView.deselectRow(at: indexPath, animated: true)
   }
}
