//
//  WishlistViewController.swift
//  ProbaDruga
//
//  Created by Jola on 04/10/22.
//

import UIKit
import Apollo


class WishlistViewController: BaseViewController {
    @IBOutlet var collectionView: UICollectionView!
    @IBOutlet var subTitleLabel: UILabel!
    @IBOutlet var noAccessView: UIView!
    
    var wishListItems: [GetCustomerWishListQuery.Data.Customer.Wishlist?]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Wishlist"
        
        collectionView.delegate = self
        collectionView.dataSource = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setNavigationBarButton()
        
        if CustomUserDefaults.isCustomerLoggedIn() {
            getWishListData()
            noAccessView.isHidden = true
        } else {
            noAccessView.isHidden = false
        }
    }
    
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
    
    @IBAction func actionOnSignIn(_ sender: UIButton) {
        doSignIn()
    }
    
    func doSignIn() {
        let storyBoard = UIStoryboard(name: "Main", bundle: nil)
        guard let vC = storyBoard.instantiateViewController(withIdentifier: "SignInViewController") as? SignInViewController else {
            return
        }
        vC.isFirstFlow = true
        vC.delegate = self
        self.present(vC, animated: true, completion: nil)
    }
    
    func getWishListData() {
        ProgressHUD.show()
        ApolloManager.shared.client.clearCache()
        ApolloManager.shared.client.fetch(query: GetCustomerWishListQuery()) { result in
            ProgressHUD.dismiss()
            switch result {
            case .success(let graphQLResult):
                if let wishlists = graphQLResult.data?.customer?.wishlists {
                    self.wishListItems?.removeAll()
                    self.wishListItems = wishlists
                    self.collectionView.reloadData()
                    
                    self.subTitleLabel.text = "Your wishlist is empty"
                    if (self.wishListItems?.count ?? 0) > 0 {
                        if let tempWishList = self.wishListItems?[0] {
                            self.subTitleLabel.text = tempWishList.name
                        }
                    }
                }
            case .failure(let error):
                print("Error loading data \(error)")
            }
        }
    }
}

extension WishlistViewController: RefreshControllerDelegate {
    func refreshControllerAction() {
        if CustomUserDefaults.isCustomerLoggedIn() {
            getWishListData()
            noAccessView.isHidden = true
        } else {
            noAccessView.isHidden = false
        }
    }
}


extension WishlistViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return wishListItems?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return wishListItems?[section]?.itemsV2?.items.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "WishListCollectionViewCell", for: indexPath) as! WishListCollectionViewCell
        if let wishListObj = wishListItems?[indexPath.section] {
            let wishListItem = wishListObj.itemsV2?.items[indexPath.row]
            cell.addRemoveFromFavouriteHandler = {
                ProgressHUD.show()
                self.removeItemFromWishlist(wishListId: wishListObj.id!, wishListItemId: wishListItem!.id, completionHandlerCart: { isSuccessful in
                    ProgressHUD.dismiss()
                    self.getWishListData()
                })
            }
            
            cell.setData(wishListItem: wishListItem!)
        }
        
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let dataObj = wishListItems?[indexPath.section]?.itemsV2?.items[indexPath.row] {
            let storyBoard = UIStoryboard(name: "Main", bundle: nil)
            guard let vC = storyBoard.instantiateViewController(withIdentifier: "ProductDetailsViewController") as? ProductDetailsViewController else { return }
            vC.sku = dataObj.product?.sku ?? ""
            self.navigationController?.pushViewController(vC, animated: true)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let width = UIScreen.main.bounds.width/2
        return CGSize(width: width, height: width*1.2)
    }
}
