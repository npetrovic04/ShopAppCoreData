//
//  ProductDetailsViewController.swift
//  ProbaDruga
//
//  Created by Jola on 14.5.22..
//

import Foundation
import UIKit

class ProductDetailsViewController: BaseViewController {
    var product: GetProductBySkuQuery.Data.Product.Item?
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var image: UIImageView!
    @IBOutlet var quantityBorderView: UIStackView!
    @IBOutlet var quantityLabel: UILabel!
    @IBOutlet var bottomActionView: UIView!
    @IBOutlet var addToWishListButton: UIButton!
    
    var qty = 1
    var sku: String?
    var wishListItemIds = [String: WishListIndex]()
    
    override func viewDidLoad() {
      super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.reloadData()
        
        bottomActionView.isHidden = true
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let sku = sku {
            getProductDetail(sku: sku)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        quantityBorderView.layer.cornerRadius = 15
        quantityBorderView.layer.borderWidth = 1
        quantityBorderView.layer.borderColor = UIColor.systemGray2.cgColor
        quantityBorderView.layer.masksToBounds = true
    }
    
    @IBAction func actionOnMinusQty(_ sender: UIButton) {
        qty -= 1
        if qty < 1 {
            qty = 1
            self.showAlert(title: "Alert", message: "Minimum 1 quantity.")
        }
        quantityLabel.text = "\(qty)"
    }
    
    @IBAction func actionOnPlusQty(_ sender: UIButton) {
        qty += 1
        quantityLabel.text = "\(qty)"
    }
    
    
    @IBAction func actionOnAddToCart(_ sender: UIButton) {
        if CustomUserDefaults.isCustomerLoggedIn() {
            if let productSku = product?.sku {
                ProgressHUD.show()
                addProductToCart(quantity: Double(qty), sku: productSku, completionHandlerCart: { isSuccessful in
                    ProgressHUD.dismiss()
                })
            }
        } else {
            let alert = UIAlertController(title: "Alert", message: "Please login to view price and proceed add to cart.", preferredStyle: .alert)
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
    
    
    @IBAction func actionOnAddRemoveToWishList(_ sender: UIButton) {
        if CustomUserDefaults.isCustomerLoggedIn() {
            if let productSku = product?.sku {
                ProgressHUD.show()
                if !self.wishListItemIds.keys.contains(self.sku!) {
                    addItemToWishlist(quantity: Double(qty), sku: productSku, completionHandlerCart: { isSuccessful in
                        ProgressHUD.dismiss()
                        self.getWishListData()
                    })
                } else {
                    if let tempWishListIndex = self.wishListItemIds[self.sku!] {
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
    
    
    func getProductDetail(sku: String) {
        let query = GetProductBySkuQuery(sku: sku)
        
        ProgressHUD.show()
        ApolloManager.shared.client.fetch(query: query, cachePolicy: .returnCacheDataAndFetch) { result in
            ProgressHUD.dismiss()
            switch result {
            case .success(let graphQLResult):
                
                if let productItems = graphQLResult.data?.products?.items, productItems.count > 0 {
                    self.product = productItems[0]
                    
                    if let product = self.product {
                        self.title = product.name
                        self.image.load(urlString: (product.image?.url)!)
                    }
                    
                    self.quantityLabel.text = "\(self.qty)"
                    self.tableView.reloadData()
                    self.bottomActionView.isHidden = false
                    self.getWishListData()
                }
            case .failure(let error):
                print("Error loading data \(error)")
            }
        }
    }
    
    func getWishListData() {
        ProgressHUD.show()
        ApolloManager.shared.client.clearCache()
        self.wishListItemIds = [:]
        ApolloManager.shared.client.fetch(query: GetCustomerWishListQuery()) { result in
            ProgressHUD.dismiss()
            switch result {
            case .success(let graphQLResult):
                if let wishlists = graphQLResult.data?.customer?.wishlists {
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
                
                let isInWishList = self.wishListItemIds.keys.contains(self.sku!)
                self.addToWishListButton.tintColor = isInWishList ? UIColor.black : UIColor.lightGray
                
            case .failure(let error):
                print("Error loading data \(error)")
            }
        }
    }
}

extension ProductDetailsViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: "ProductDetailsCell")!

        if let product = product {
            if indexPath.row == 0 {
                cell.textLabel?.text = "ID"
                if let productID = product.id {
                    cell.detailTextLabel?.text = "\(productID)"
                }
            }
            else if indexPath.row == 1 {
                cell.textLabel?.text = "NAME"
                cell.detailTextLabel?.text = product.name
            }
            else if indexPath.row == 2 {
                cell.textLabel?.text = "SKU"
                cell.detailTextLabel?.text = product.sku
            }
            else if indexPath.row == 3 {
                cell.textLabel?.text = "PRICE"
                
                let currencySymbol = product.priceRange.minimumPrice.finalPrice.currency?.rawValue ?? "$"
                cell.detailTextLabel?.text = "\(currencySymbol) \(product.priceRange.minimumPrice.finalPrice.value ?? 0.0)"
            }
        } else {
            cell.textLabel?.text = ""
            cell.detailTextLabel?.text = ""
        }
        return cell
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            
            return CustomUserDefaults.isCustomerLoggedIn() ? 4 : 3
      }
        return 1
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
      return section == 0 ? "Product Details" : ""
    }
    
}

extension ProductDetailsViewController: RefreshControllerDelegate {
    func refreshControllerAction() {
        tableView.reloadData()
    }
}
