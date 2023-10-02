//
//  ProductListCollectionCell.swift
//  ProbaDruga
//
//  Created by Jola on 10/08/22.
//

import UIKit
import SDWebImage

class ProductListCollectionCell: UICollectionViewCell {
    @IBOutlet var productImage: UIImageView!
    @IBOutlet var productName: UILabel!
    @IBOutlet var addToWishListButton: UIButton!
    
    var addRemoveFromFavouriteHandler:()->Void = { }
    
    func setData(product: GetCategoryProductsQuery.Data.Product.Item) {
        // Setting data to display
        productName.text = product.name?.capitalized
        productImage.sd_setImage(with: URL(string: product.image?.url ?? ""), completed: nil)
    }
    
    @IBAction func actionOnAddToWishlist(_ sender: UIButton) {
        addRemoveFromFavouriteHandler()
    }
}
