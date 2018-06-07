//
//  CollectionView.swift
//  ImgurPlay
//
//  Created by Ken Streger on 6/1/18.
//  Copyright © 2018 Ken Streger. All rights reserved.
//


// **********************************************************************************************************************
//
//  The Collection View is it's own delegate and datasource, and is coupled to it's super view controller only via
//   a single storyboard outlet.
//
//  This Collection View performs the following functions:
//
//     - Serves as its own controller
//     - Initializes and sets up itself
//     - Receives a notification that new data is available via a reload notification.  The VIEWMODEL has no
//       knowledge of it.
//     - It maintains the row number of the last selected cell in the 'selectedRow' property.
//
// **********************************************************************************************************************


import UIKit

let kReloadNotification = "com.kenstreger.reloadNotification"

class CollectionView: UICollectionView, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

    @IBOutlet weak public var collectionView: UICollectionView!
    @IBOutlet weak public var mainVC: ViewController!

    // IndexPath of the last active collection cell.
    private var activeCellIndexPath: IndexPath?
    
    // Used to format the cell size and spacing of the collection view
    private var estimatedCellWidth = 160.0
    private var cellMarginSize = 16.0
    
    public var selectedRow: Int?
    
    // MARK: - Initialization
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.delegate = self
        self.dataSource = self

        NotificationCenter.default.addObserver(self, selector: #selector(processReloadNotification), name: NSNotification.Name(rawValue: kReloadNotification), object: nil)

        setUpCollectionViewGrid()
    }


    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    
    // MARK: - Initialization - VIEWMODEL has changed processing
    
    @objc func processReloadNotification() {
        self.reloadData()
    }
    
    
    // MARK: - Collection View Delegates
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return mainVC.viewModel.numberOfCells
    }
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "imgurCell", for: indexPath) as! CollectionViewCell
        cell.configCell(row: indexPath.row)
        return cell
    }
    
    
    // asks the delegate for the size of the cell
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {

        let length = calculateSide()
        return CGSize(width: length, height: length)
    }
    
    
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let cell = collectionView.cellForItem(at: indexPath) as! CollectionViewCell
        
        let row = indexPath.row
        
        if selectedRow != nil {
            if row == selectedRow {
                selectedRow = nil  // nothing is selected now
                cell.backgroundColor = UIColor.black
                cell.cellButtonsContainerView.isHidden = true
            } else {
                selectedRow = row
                cell.backgroundColor = UIColor.green
                cell.cellButtonsContainerView.isHidden = false
            }
        } else {
            selectedRow = row
            cell.backgroundColor = UIColor.green
            cell.cellButtonsContainerView.isHidden = false
        }
        collectionView.reloadData()
    }
    
    
    
    
    // MARK: - Collection View Sizing methods
    
    // these functions support the setup of the collection view format
    
    func setUpCollectionViewGrid() {
        let flow = self.collectionViewLayout as! UICollectionViewFlowLayout
        flow.minimumInteritemSpacing = CGFloat(self.cellMarginSize)
        flow.minimumLineSpacing = CGFloat(self.cellMarginSize)
    }

    func calculateSide() -> CGFloat {
        // for very larger iPads, looks better with larger cells
        let collectionViewWidth = min(self.frame.size.width, self.frame.size.height)
        if collectionViewWidth > 750 {
            estimatedCellWidth = 250.0
        }
        let estWidth = CGFloat(estimatedCellWidth)
        let cellCount = floor(CGFloat(self.frame.size.width / estWidth))
        let width = (self.frame.size.width - (CGFloat(cellMarginSize) * CGFloat(cellCount))) / cellCount

        return width
    }
    
    
    // when the cell data is modified on data model loading, the variable maintaining proper cell highlighting is reset.
    // Kept as a separate routine in case other additional properties need to be set here
    
    func resetSelection() {
        activeCellIndexPath = nil
    }

}
