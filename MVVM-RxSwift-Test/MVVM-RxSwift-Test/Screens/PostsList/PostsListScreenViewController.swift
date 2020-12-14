//
//  ViewController.swift
//  MVVM-RxSwift-Test
//

import UIKit
import RxSwift
import RxCocoa

class PostsListScreenViewController: UIViewController {

   let bag = DisposeBag()
   
   private var viewModel:PostsListViewModel?
   
   @IBOutlet private weak var table:UITableView?
   
   static func create(viewModel:PostsListViewModel) -> PostsListScreenViewController? {
      
      let mainBoard = UIStoryboard.init(name: "Main", bundle: nil)
      
      let postsScreen = mainBoard.instantiateViewController(identifier: "PostsListScreenViewController") as? PostsListScreenViewController
      
      postsScreen?.viewModel = viewModel
      
      return postsScreen
   }
   
   override func viewDidLoad() {
      super.viewDidLoad()
      
      navigationController?.navigationBar.prefersLargeTitles = true
      
      guard let vm = viewModel, let postsTable = table else {
         print("No View Model on ViewDidLoad")
         return
      }

      //fast answer to deselect cell on selection
      postsTable.rx
         .setDelegate(self)
         .disposed(by: bag)
      
      navigationItem.title = vm.title
      
      vm.fetchPostViewModels()
         .observe(on: MainScheduler.instance)
         .bind(to: postsTable.rx.items(cellIdentifier:"PostCell")) { index, postModel, cell in
            var state = cell.defaultContentConfiguration()
            
            state.text = postModel.titleText
            
            state.secondaryText = postModel.detailsText
            
            cell.contentConfiguration = state
         }
         .disposed(by:bag)
      
      //subscribe on cell tap
      postsTable.rx.itemSelected.subscribe {[weak self] (event) in
         self?.viewModel?.selectPostAt(event.row)
      }.disposed(by: bag)
   }
}

extension PostsListScreenViewController : UITableViewDelegate {
   func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
      tableView.deselectRow(at: indexPath, animated: true)
   }
}

