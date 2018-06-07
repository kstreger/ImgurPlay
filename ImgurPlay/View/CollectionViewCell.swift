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
 /   This VIEW loads only VIEWMODEL data.
 /
 / ******************************************************************************************************
 */


public class CollectionViewCell: UICollectionViewCell {
    
    var cellRow: Int?
    
    @IBOutlet weak var cellImageView: UIImageView!
    @IBOutlet weak var cellButtonsContainerView: UIView!
    
    @IBOutlet weak var collectionView: CollectionView!
    @IBOutlet weak var mainViewController: ViewController!
    
    
    // MARK: - Configure the cell
    
    // loads thumbnail into image view and checks status of whether the cell is selected to display action icons and green highlight
    
    public func configCell(row: Int) {
        
        cellRow = row
        
        self.cellImageView.image = nil  // uncache image
        cellButtonsContainerView.alpha = 0.75
        
        if let selectedRow = collectionView.selectedRow {
            if row == selectedRow {
                self.backgroundColor = UIColor.green
                cellButtonsContainerView.isHidden = false
            } else {
                self.backgroundColor = UIColor.black
                cellButtonsContainerView.isHidden = true
            }
        } else {  // initial state
            self.backgroundColor = UIColor.black
            cellButtonsContainerView.isHidden = true
        }
        
        let cellVM = mainViewController.viewModel.getCellViewModel(at: row)
        
        self.cellImageView.image = cellVM.thumbnailImage
    }
    
    
    
    // MARK: - Delete and View Full Image Button Actions
    
    // delete function
    
    @IBAction private func deleteImage(_ sender: AnyObject) {
        
        guard let row = cellRow else {
            return
        }
        mainViewController.viewModel.deleteImage(row: row)
    }
    
    
    
    // view full image function
    
    @IBAction private func viewFullImage(_ sender: AnyObject) {

        guard let row = cellRow else {
            return
        }
        
        // if there is no image link, or the image was already retrieved, then exit routine
        if mainViewController.viewModel.imagesViewModelArray[row].link == "" {
            return
        }
        if mainViewController.viewModel.imagesViewModelArray[row].image != nil {
            mainViewController.showFullImage(image: mainViewController.viewModel.imagesViewModelArray[row].image)
            return
        }

        // retrieve full image and load it into the model
        mainViewController.viewModel.getFullImgurImage(row: row)
    }
    
}
