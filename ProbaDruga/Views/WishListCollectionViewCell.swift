//
//  WishListCollectionViewCell.swift
//  ProbaDruga
//
//  Created by Jola on 10/10/22.
//

import UIKit
import SDWebImage

class WishListCollectionViewCell: UICollectionViewCell {
    @IBOutlet var productImage: UIImageView!
    @IBOutlet var productName: UILabel!
    @IBOutlet var addToWishListButton: UIButton!
    
    var addRemoveFromFavouriteHandler:()->Void = { }
    
    func setData(wishListItem: GetCustomerWishListQuery.Data.Customer.Wishlist.ItemsV2.Item) {
        // Setting data to display
        productName.text = wishListItem.product?.name
        productImage.sd_setImage(with: URL(string: wishListItem.product?.image?.url ?? ""), completed: nil)
    }
    
    @IBAction func actionOnAddToWishlist(_ sender: UIButton) {
        addRemoveFromFavouriteHandler()
    }
}
