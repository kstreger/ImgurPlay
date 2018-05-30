//
//  CollectionViewCell.swift
//  ImgurPlay
//
//  Created by Ken Streger on 5/27/18.
//  Copyright © 2018 Ken Streger. All rights reserved.
//

import UIKit


/* ******************************************************************************************************
 /
 /   The CollectionViewCell manages the cell of the Collection View.
 /
 /   When the cell is configured in configCell, it checks the status of the cell to see if the icons and
 /   green outline need to be displayed.
 /
 /   The delete button and view button actions are also processed here.
 /
 / ******************************************************************************************************
 */



public class CollectionViewCell: UICollectionViewCell {
    
    var row: Int?
    
    weak var vc: ViewController?
    
    @IBOutlet weak var cellImageView: UIImageView!
    @IBOutlet weak var cellButtonsContainerView: UIView!

    
    
    // loads thumbnail into image view and checks status of whether the cell is selected to display action icons and green highlight
    
    public func configCell(row: Int) {
        
        self.row = row
        self.cellImageView.image = nil  // uncache image
        cellButtonsContainerView.alpha = 0.75
        
        if imagesArray[row].thumbnailImage != nil {
            self.cellImageView.image = imagesArray[row].thumbnailImage
        }
        
        if imagesArray[row].isActive {
            self.backgroundColor = UIColor.green
            cellButtonsContainerView.isHidden = false
        } else {
            self.backgroundColor = UIColor.black
            cellButtonsContainerView.isHidden = true
        }
        
    }
    
    // delete function
    
    @IBAction private func deleteImage(_ sender: AnyObject) {
        
        let deleteHash = imagesArray[row!].deletehash
        
        vc?.imgurAPIHelper.deleteImage(deleteHash: deleteHash) { (response, error) in
            if (error != nil) {
                Utilities.displayMessage("Error", message: error!.localizedDescription, vc: self.vc!)
            } else {
                Utilities.displayMessage("Success", message: "Successfully deleted image!", vc: self.vc!)
                // remove from data array
                imagesArray.remove(at: self.row!)
                // redisplay
                self.vc!.resetSelection()
                self.vc!.collectionView.reloadData()
            }
        }
    }
    
    
    // view full image function
    
    @IBAction private func viewFullImage(_ sender: AnyObject) {

        guard let row = self.row else {
            return
        }
        
        // if there is no image link, or the image was already retrieved, then exit routine
        if imagesArray[row].link == "" {
            return
        }
        if imagesArray[row].image != nil {
            vc!.showFullImage(image: imagesArray[row].image!)
            return
        }

        // retrieve full image and load it into the model

        Utilities.startActivityIndicator(vc!.activityIndicatorView)
        vc?.imgurAPIHelper.getFullImage(imageFilename: imagesArray[row].link) {
            (response, error) in
            if (error != nil) {
                Utilities.displayMessage("Error", message: error!.localizedDescription, vc: self.vc!)
                Utilities.stopActivityIndicator(self.vc!.activityIndicatorView)
            } else {
                if let response = response {
                    Utilities.stopActivityIndicator(self.vc!.activityIndicatorView)
                    imagesArray[self.row!].image = response as? UIImage
                    self.vc!.showFullImage(image: imagesArray[self.row!].image!)
                }
            }
        }
    }
    
}
