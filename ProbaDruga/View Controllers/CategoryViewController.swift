//
//  CategoryViewController.swift
//  ProbaDruga
//
//  Created by Jola on 14.6.22..
//

import Foundation
import UIKit
import SideMenu

class CategoryViewController: UITableViewController {
    var categories: [CategoryListQuery.Data.CategoryList.Child] = []
    var parentCategoryId = "MjY0Mg=="
    var parentCategoryTitle = "Products"
    
    var isRootController = true
    
    override func viewDidLoad() {
       super.viewDidLoad()
        
        // checking to set menu button if its root controller
        if isRootController {
            setNavigationBarButton()
        }
        
        self.title = parentCategoryTitle
        loadData()
    }
    
    // hamburger icon
    func setNavigationBarButton() {
        let leftNavBarButton = UIBarButtonItem(image: UIImage(systemName: "line.3.horizontal"), style: .plain, target: self, action: #selector(didTapMenu))
        leftNavBarButton.tintColor = .black
        self.navigationItem.leftBarButtonItem  = leftNavBarButton
    }
    
    @objc func didTapMenu() {
        // opens side menu
        sideMenuController?.revealMenu()
        sideMenuController?.menuViewController.viewWillAppear(true)
    }
    
    // function that obtains the categories
    func loadData() {
        let query = CategoryListQuery(categoryId: parentCategoryId)
        ProgressHUD.show()
        ApolloManager.shared.client.fetch(query: query, cachePolicy: .returnCacheDataAndFetch) { result in
            ProgressHUD.dismiss()
            switch result {
            case .success(let graphQLResult):
                if let categories = graphQLResult.data?.categoryList![0]?.children!.compactMap({ $0 }) {
                    let filteredCategories = categories.filter {$0.includeInMenu == 1}
                    self.categories = filteredCategories
                    self.tableView.reloadData()
                }
            case .failure(let error):
                print("Error loading data \(error)")
            }
        }
    }
}

extension CategoryViewController {
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
      return categories.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
      // swiftlint:disable:next force_unwrapping
        let cell = tableView.dequeueReusableCell(withIdentifier: "CategoriesCell")!

        let category = categories[indexPath.row]
        cell.textLabel?.text = category.name
        
        return cell
    }
    
    // if there are children, the Category View opens again, and if there are none, then the Collection View opens
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let category = categories[indexPath.row]
        
        let storyBoard = UIStoryboard(name: "Main", bundle: nil)
        if (category.children?.count ?? 0) > 0 {
            // Navigation to Sub Category Listing Screen
            guard let vC = storyBoard.instantiateViewController(withIdentifier: "CategoryViewController") as? CategoryViewController else {
                return
            }
            vC.isRootController = false
            vC.parentCategoryId = category.uid
            vC.parentCategoryTitle = category.name?.capitalized ?? ""
            self.navigationController?.pushViewController(vC, animated: true)
        } else {
            // Navigation to Product Listing Screen
            guard let vC = storyBoard.instantiateViewController(withIdentifier: "ProductViewController") as? ProductViewController else {
                return
            }
            vC.productCategoryId = category.uid
            vC.productCategoryTitle = category.name?.capitalized ?? ""
            self.navigationController?.pushViewController(vC, animated: true)
        }
    }
}
