//
//  ViewController.swift
//  ImgurPlay
//
//  Created by Ken Streger on 5/23/18.
//  Copyright © 2018 Ken Streger. All rights reserved.
//

import UIKit

import AeroGearHttp
import AeroGearOAuth2
import Photos
import SafariServices

// **********************************************************************************************************************
//
// This Main View Controller performs the following functions:
//
//     - Serves as the UICollectionView controller
//     - Captures and drives "login"(retry) and "add image" button actions (The touches on the collection view cell
//        are captured and processed in the CollectionViewCell
//     - Drives the use of the Photo Library via the UIImagePickerController
//     - Sets up a gestureRecognizer for the imageView where a full screen image had been displayed. The touch gesture
//       hides the image.
//
// **********************************************************************************************************************

class ViewController: UIViewController, UINavigationControllerDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    // MARK: - Instance properties
    
    // Used to format the cell size and spacing of the collection view
    private var estimatedCellWidth = 160.0
    private var cellMarginSize = 16.0
    
    // IndexPath of the last active collection cell.
    private var activeCellIndexPath: IndexPath?
    
    // the ImgurAPIHelper class is a wrapper around all Imgur requests
    public let imgurAPIHelper = ImgurAPIHelper()
    public let imagesModelHelper = ImagesModelHelper()

    // Used to access the user Photo Library
    private var imagePicker = UIImagePickerController()
    
    // The imageView UI property is used to display the selected collection cell thumbnail as
    // the user requests a full screen view from the view button in the CollectionViewCell
    @IBOutlet weak private var imageView: UIImageView!
    
    @IBOutlet weak public var collectionView: UICollectionView!
    @IBOutlet weak private var loginButton: UIButton!
    @IBOutlet weak public var activityIndicatorView: UIActivityIndicatorView!

    
    // MARK: - Init, Setup and Maintenance delegates

    override func viewDidLoad() {
        super.viewDidLoad()

        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.mainViewController = self

        setUpCollectionViewGrid()
        setUpTapGestureForImageView()
        Utilities.stopActivityIndicator(activityIndicatorView)
        
        DispatchQueue.main.async {
            self.getProcessLoadImageLinks()
        }
    }
    
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    private func setUpTapGestureForImageView() {
        let singleTapGesture: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didSingleTapFullImage(_:)))
        singleTapGesture.numberOfTapsRequired = 1
        self.imageView.addGestureRecognizer(singleTapGesture)
        self.imageView.alpha = 0.0
    }
    
    
    // MARK: - Button and Gesture Actions
    

    // The login action is only explicitly bid by the user if the login had previously been aborted by the user.
    // The action requests the collection view to be loaded (downloading the image info of the user)
    // and the initial login and access token is a byproduct of that request
    
    @IBAction private func retryLogin(_ sender: AnyObject) {
        self.getProcessLoadImageLinks()
    }

    
    // addImages is bid from the "Add Images" button.  It opens the Photo Library in an image picker after checking authorizations
    // After the user enters the Photo Library to select the image to upload, all further processing
    // is handled by the image picker delegate and the uploadImage method
    
    @IBAction private func addImages(_ sender: AnyObject) {

        let photos = PHPhotoLibrary.authorizationStatus()
        if photos == .notDetermined {
            PHPhotoLibrary.requestAuthorization({status in
                if status == .authorized{
                    self.imagePicker.sourceType = .photoLibrary
                    self.imagePicker.delegate = self
                    self.present(self.imagePicker, animated: true, completion: nil)
                }
            })
        } else {
            if photos == .authorized {
                imagePicker.sourceType = .photoLibrary
                imagePicker.delegate = self
                present(imagePicker, animated: true, completion: nil)
            } else {
                Utilities.displayMessage("Photo Library Access Denied",
                    message: "To allow ImgurPlay to access your Photo Library, got to the Settings App and change the Privacy settings for Photos", vc: self)
            }
        }
    }
    
    
    // gestureRecognizer touch action for the full image. When the full image is displayed, a tap on it hides it.
    
    @objc func didSingleTapFullImage(_ gesture: UITapGestureRecognizer) {
        UIView.animate(withDuration: 0.75, animations: {
            self.imageView.alpha = 0.0
        })
    }
    
    
    // MARK: - Download Image Info and thumbnails for the Collection View

    // get all image info for user account

    private func getProcessLoadImageLinks() {
        
        Utilities.startActivityIndicator(activityIndicatorView)
        imgurAPIHelper.getImageLinks() { (response, error) in
            if (error != nil) {
                Utilities.stopActivityIndicator(self.activityIndicatorView)
                Utilities.displayMessage("Error", message: error!.localizedDescription, vc: self)
            } else {
                guard let response = response else {
                    Utilities.stopActivityIndicator(self.activityIndicatorView)
                    Utilities.displayMessage("Error", message: "No data returned", vc: self)
                    return
                }
                self.loginButton.isHidden = true
                self.parseImageList(response: response)
                Utilities.stopActivityIndicator(self.activityIndicatorView)
            }
        }
    }
    
    
    // for each cell, a smaller thumbnail is loaded to minimize user's data usage. The large image is only
    // requested when a user requests it from the cell
    
    func loadThumbnailImage(index: Int) {
        
        // if there is no image link, or the image was already retrieved, then exit routine
        if imagesArray[index].thumbnailLink == "" || imagesArray[index].thumbnailImage != nil {
            return
        }
        // retrieve thumbnail and load it into the model
        imgurAPIHelper.getThumbnailImage(imageFilename: imagesArray[index].thumbnailLink) {
            (response, error) in
            if (error != nil) {
                Utilities.displayMessage("Error", message: error!.localizedDescription, vc: self)
            } else {
                if let response = response {
                    imagesArray[index].thumbnailImage = response as? UIImage
                    self.collectionView.reloadData()
                }
            }
        }
    }
    
    // when the cell data is modified on data model loading, the variable maintaining proper cell highlighting is reset.
    // Kept as a separate routine in case other additional properties need to be set here
    
    public func resetSelection() {
        activeCellIndexPath = nil
    }
    
    
    // drives the process to load the image api response into the database and load associated thumbnail images
    
    func parseImageList(response: Any?) {

        let (imageResponseArray, validation) = imagesModelHelper.validateImageListResponse(response, vc: self)
        if validation == .Invalid {
            return
        }
        imagesArray.removeAll()
        for (index, imageDict) in imageResponseArray.enumerated() {
            imagesModelHelper.addDictEntryToModel(imageDict: imageDict)
            loadThumbnailImage(index: index)
        }
    }

    
    
    // driven from the UIImagePickerController delegate after a user selects an image from the Photo Library
    
    func uploadImage() {
        
        Utilities.startActivityIndicator(activityIndicatorView)
        
        guard let imageData = Utilities.convertImageToData(imageView.image) else {
            Utilities.displayMessage("Error Converting Image to Data", message: "Select an image to upload first.", vc: self)
            return
        }
        imgurAPIHelper.uploadImage(imageData: imageData) {
            (response, error) in
            
            if (error != nil) {
                Utilities.stopActivityIndicator(self.activityIndicatorView)
                Utilities.displayMessage("Error", message: error!.localizedDescription, vc: self)
            } else {
                Utilities.stopActivityIndicator(self.activityIndicatorView)
                Utilities.displayMessage("Success", message: "Successfully uploaded!", vc: self)
                self.getProcessLoadImageLinks()
            }
        }
    }
    
     
    // MARK: - Collection View Sizing methods
    
    // these functions support the setup of the collection view format
    
    func setUpCollectionViewGrid() {
        let flow = collectionView?.collectionViewLayout as! UICollectionViewFlowLayout
        flow.minimumInteritemSpacing = CGFloat(self.cellMarginSize)
        flow.minimumLineSpacing = CGFloat(self.cellMarginSize)
    }
    
    func calculateSide() -> CGFloat {
        // for very larger iPads, looks better with larger cells
        let collectionViewWidth = min(collectionView.frame.size.width, collectionView.frame.size.height)
        if collectionViewWidth > 750 {
            estimatedCellWidth = 250.0
        }
        let estWidth = CGFloat(estimatedCellWidth)
        let cellCount = floor(CGFloat(self.collectionView.frame.size.width / estWidth))
        let width = (self.collectionView.frame.size.width - (CGFloat(cellMarginSize) * CGFloat(cellCount))) / cellCount
        
        return width
    }
    
    
    // MARK: - Collection View Delegates
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imagesArray.count
    }
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "imgurCell", for: indexPath) as! CollectionViewCell
        
        loadThumbnailImage(index: indexPath.row)
        
        unowned let weakSelf = self
        cell.vc = weakSelf
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
        if imagesArray[indexPath.row].isActive {
            imagesArray[indexPath.row].isActive = false
            cell.backgroundColor = UIColor.black
            cell.cellButtonsContainerView.isHidden = true
        } else {
            imagesArray[indexPath.row].isActive = true
            cell.backgroundColor = UIColor.green
            cell.cellButtonsContainerView.isHidden = false
        }

        // reset previous cell if different than this cell
        if let activeCellIndexPath = activeCellIndexPath {
            if indexPath != activeCellIndexPath {
                imagesArray[activeCellIndexPath.row].isActive = false
                let prevActiveCell = collectionView.cellForItem(at: activeCellIndexPath)
                if let prevActiveCell = prevActiveCell {
                    prevActiveCell.backgroundColor = UIColor.black
                    cell.cellButtonsContainerView.isHidden = true
                }
            }
        }
        
        // save for resetting of the previous cell next time around
        activeCellIndexPath = indexPath
        
        collectionView.reloadData()
    }
    

    // Bid from the collection cell when the user touches the view icon
    
    public func showFullImage(image: UIImage) {
        imageView.image = image
        self.view.bringSubview(toFront: imageView)
        UIView.animate(withDuration: 0.75, animations: {
            self.imageView.alpha = 1.0
        })
    }

}

extension ViewController: SFSafariViewControllerDelegate {

    // if the user aborts out of the credentials screen invoked by the OAuth2 process
    // it will be captured here to display a message to log in again.
    
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        
        self.loginButton.isHidden = false
        Utilities.displayMessage("Login Not Successful", message: "Try logging in again.", vc: self)
        controller.dismiss(animated: true, completion: nil)
        let deadline = DispatchTime.now() + 2
        DispatchQueue.main.asyncAfter(deadline: deadline) {
            Utilities.stopActivityIndicator(self.activityIndicatorView)
        }
    }
}


extension ViewController: UIImagePickerControllerDelegate {
    
    // if an image is selected from the image picker using the Photo Library, save it in a local image for uploading, and bid the process to upload
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        imageView.image = info[UIImagePickerControllerOriginalImage] as? UIImage
        imagePicker.dismiss(animated: true, completion: nil)
        
        DispatchQueue.main.async {
            self.uploadImage()
        }
    }
    
    // User canceled out of image picker using the Photo Library - dismiss controller
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
}


