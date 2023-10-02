//
//  ProductViewController.swift
//  ProbaDruga
//
//  Created by Jola on 19.6.22..
//

import Foundation
import UIKit

struct WishListIndex {
    let wishListId: String!
    let wishListItemId: String!
}


class ProductViewController: BaseViewController {
    @IBOutlet var collectionView: UICollectionView!
    
    var products: [GetCategoryProductsQuery.Data.Product.Item] = []
    var productCategoryTitle = "Categories"
    var productCategoryId = ""
    
    var currentPage = 1
    var pageSize = 6
    var isLoading = false
    var isLastDataFetched = false
    
    var isRootController = false
    
    var wishListItemIds = [String: WishListIndex]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // checking to set menu button if its root controller
        if isRootController {
            setNavigationBarButton()
        }
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        self.title = productCategoryTitle
        
        self.products = []
        loadData(category: productCategoryId)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.wishListItemIds = [String: WishListIndex]()
        if CustomUserDefaults.isCustomerLoggedIn() {
            getWishListData()
        }
    }
    
    // hamburger
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
}

extension ProductViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return products.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if indexPath.row == products.count - 2, !isLoading && !isLastDataFetched {
            loadData(category: productCategoryId)
        }
        
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ProductListCollectionCell", for: indexPath) as! ProductListCollectionCell
        let dataObj = products[indexPath.row]
        
        let isInWishList = wishListItemIds.keys.contains(dataObj.sku!)
        cell.addToWishListButton.tintColor = isInWishList ? UIColor.black : UIColor.lightGray
        
        cell.addRemoveFromFavouriteHandler = {
            if CustomUserDefaults.isCustomerLoggedIn() {
                if let productSku = dataObj.sku {
                    ProgressHUD.show()
                    if !isInWishList {
                        self.addItemToWishlist(quantity: 1, sku: productSku, completionHandlerCart: { isSuccessful in
                            ProgressHUD.dismiss()
                            self.getWishListData()
                        })
                    } else {
                        if let tempWishListIndex = self.wishListItemIds[productSku] {
                            self.removeItemFromWishlist(wishListId: tempWishListIndex.wishListId, wishListItemId: tempWishListIndex.wishListItemId, completionHandlerCart: { isSuccessful in
                                ProgressHUD.dismiss()
                                self.getWishListData()
                            })
                        }
                    }
                }
            } else {
                let alert = UIAlertController(title: "Alert", message: "Please login to add in your wishlist.", preferredStyle: .alert)
                let okBtn = UIAlertAction(title: "Login Now", style: .default, handler: {_ in
                    let storyBoard = UIStoryboard(name: "Main", bundle: nil)
                    guard let vC = storyBoard.instantiateViewController(withIdentifier: "SignInViewController") as? SignInViewController else {
                        return
                    }
                    vC.delegate = self
                    vC.isFirstFlow = true
                    self.present(vC, animated: true, completion: nil)
                })
                
                let cancelBtn = UIAlertAction(title: "Cancel", style: .destructive, handler: {_ in })
                
                alert.addAction(okBtn)
                alert.addAction(cancelBtn)
                self.present(alert, animated: true, completion: nil)
            }
        }
        
        cell.setData(product: dataObj)
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let storyBoard = UIStoryboard(name: "Main", bundle: nil)
        guard let vC = storyBoard.instantiateViewController(withIdentifier: "ProductDetailsViewController") as? ProductDetailsViewController else { return }
        vC.sku = products[indexPath.row].sku
        self.navigationController?.pushViewController(vC, animated: true)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let width = UIScreen.main.bounds.width/2
        return CGSize(width: width, height: width*1.2)
    }
    
    func loadData(category: String?) {
        
        // Checking if data is requested from server, if yes then return to wait
        if isLoading {
            return
        }
        isLoading = true
        let categoryId = category
        let query = GetCategoryProductsQuery(categoryId: categoryId, currentPage: currentPage, pageSize: pageSize)
        
        //ProgressHUD.show()
        ApolloManager.shared.client.fetch(query: query, cachePolicy: .returnCacheDataAndFetch) { result in
            
            self.isLoading = false
            //ProgressHUD.dismiss()
            switch result {
            case .success(let graphQLResult):
                
                if let productItems = graphQLResult.data?.products?.items!.compactMap({ $0 }) {
                    if productItems.count < self.pageSize {
                        self.isLastDataFetched = true
                    }
                    self.currentPage += 1
                    self.products.append(contentsOf: productItems)
                    self.collectionView.reloadData()
                } else {
                    self.isLastDataFetched = true
                }
            case .failure(let error):
                print("Error loading data \(error)")
            }
        }
    }
    
    func getWishListData() {
        ProgressHUD.show()
        ApolloManager.shared.client.clearCache()
        ApolloManager.shared.client.fetch(query: GetCustomerWishListQuery()) { result in
            ProgressHUD.dismiss()
            switch result {
            case .success(let graphQLResult):
                if let wishlists = graphQLResult.data?.customer?.wishlists {
                    self.wishListItemIds = [String: WishListIndex]()
                    for wishlist in wishlists {
                        if let itemsList = wishlist?.itemsV2?.items {
                            for item in itemsList {
                                if let itemSKU = item?.product?.sku {
                                    self.wishListItemIds[itemSKU] = WishListIndex(wishListId: wishlist!.id, wishListItemId: item!.id)
                                }
                            }
                        }
                    }
                }
                self.collectionView.reloadData()
            case .failure(let error):
                print("Error loading data \(error)")
            }
        }
    }
   
}



extension ProductViewController: RefreshControllerDelegate {
    func refreshControllerAction() {
        loadData(category: productCategoryId)
    }
}
