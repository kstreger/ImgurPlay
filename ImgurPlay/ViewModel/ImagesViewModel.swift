
//  ImagesViewModel.swift
//  ImgurPlay
//
//  Created by Ken Streger on 5/27/18.
//  Copyright © 2018 Ken Streger. All rights reserved.
//

import UIKit

/* *****************************************************************************************************
 /
 /   The VIEWMODEL used to contain the user's Imgur images information
 /
 /   While the VIEWMODEL is nearly identical in structure to the MODEL, it does not need to be.  It's
 /   only requirement is that it satisfies the data needs of the VIEW.  There is no direct coupling
 /   between the VIEW or the MODEL.
 /
 /   Establishes properties that are set on state changes of the VIEWMODEL.  The changes invoke closures
 /   whose interfaces are created here.  The closures are defined in the VIEW, representing the
 /   changes the VIEW will make upon the state changes of the VIEWMODEL.
 /
 / ******************************************************************************************************
 */

// MARK: - The VIEWMODEL structure

struct ImageCellViewModel {
    
    var name: String
    var title: String
    var description: String
    var type: String
    var size: Int
    var datetime: Int
    var link: String
    var thumbnailLink: String
    var deletehash: String
    var thumbnailImage: UIImage? = nil
    var image: UIImage? = nil
    var isActive: Bool = false
    
    
    init(name: String, title: String, description: String, type: String, size: Int, datetime: Int, link: String, thumbnailLink: String, deletehash: String) {
        self.name = name
        self.title = title
        self.description = description
        self.type = type
        self.size = size
        self.datetime = datetime
        self.link = link
        self.thumbnailLink = thumbnailLink
        self.deletehash = deletehash
        self.thumbnailImage = nil
        self.image = nil
        self.isActive = false
    }
}


// MARK: - The VIEWMODEL main class

class ImagesViewModel {
    
    // MARK: - Properties
    
    // the ImgurAPIHelper class is a wrapper around all Imgur requests
    public let imgurAPIHelper = ImgurAPIHelper()
    public let imagesModelHelper = ImagesModelHelper()
    public let imagesViewModelHelper = ImagesViewModelHelper()
    
    
    // MARK: - VIEWMODEL Closure Interfaces
    
    // The interface for these closures are defined here and set by the VIEW.
    // When the property values below are changed, the closures as required by the
    // VIEW are executed.  This completely decouples the VIEWMODEL from the VIEW
    
    var reloadTableViewClosure: (()->())?
    
    public var imagesViewModelArray: [ImageCellViewModel] = [ImageCellViewModel]() {
        didSet {
            self.reloadTableViewClosure?()
        }
    }
    
    var updateLoadingStatus: (()->())?

    var isLoading: Bool = false {
        didSet {
            self.updateLoadingStatus?()
        }
    }
    
    
    var fullImageClosure: ((UIImage?)->())?
    
    var fullImage: UIImage? {
        didSet {
            self.fullImageClosure?(fullImage)
        }
    }
    

    var showAlertClosure: (()->())?
    var alertTitle: String?
    var alertMessage: String? {
        didSet {
            self.showAlertClosure?()
        }
    }
    
    var numberOfCells: Int {
        return imagesViewModelArray.count
    }

    
    
    // MARK: - Initialization
    
    init() {
        initClosures()
    }
    
    
    // MARK: - VIEW closures set in the VIEWMODEL
    
    
    // The interface for these closures are defined in the MODEL and set here.
    // When the associated property values in the model are changed, the closures
    // as required by the VIEWMODEL are executed. This completely decouples the
    // VIEWMODEL from the MODEL
    
    func initClosures() {
        
        updatedModelClosure = { [weak self] () in
            self?.imagesViewModelArray = (self?.imagesViewModelHelper.updateViewModel())!
        }
        
        updatedModelThumbnailClosure = { [weak self] () in
            self?.imagesViewModelArray = (self?.imagesViewModelHelper.updateViewModelThumbnail())!
        }
        
        updatedModelEntryDeletedClosure = { [weak self] (index: Int?) in
            if let index = index {
                self?.imagesViewModelArray.remove(at: index)
            }
        }
        
        updatedModelImageClosure = { [weak self] (index: Int?) in
            if let index = index {
                self?.imagesViewModelArray[index].image = (self?.imagesViewModelHelper.updateViewModelImage(index: index))!
                self?.fullImage = self?.imagesViewModelArray[index].image
            }
        }
    }

    
    // MARK: - Processing of requests for data from the VIEW
    
    // get all image info for user account
    
    func getProcessLoadImageLinks() {
        
        self.isLoading = true
        imgurAPIHelper.getImageLinks() { (response, error) in
            self.isLoading = false
            if (error != nil) {
                self.alertTitle = "Error"
                self.alertMessage = error!.localizedDescription
            } else {
                guard let response = response else {
                    self.alertTitle = "Error"
                    self.alertMessage = "No data returned"
                    return
                }
                let status = self.imagesModelHelper.parseImageList(response: response)
                if status != .Success {
                    self.alertTitle = "Error"
                    self.alertMessage = "No data returned"
                }
            }
        }
    }
    
   
    
    public func uploadImage(imageData: Data) {
        
        self.isLoading = true

        imgurAPIHelper.uploadImage(imageData: imageData) {
            (response, error) in
            
            self.isLoading = false
            if (error != nil) {
                self.alertTitle = "Error"
                self.alertMessage = error!.localizedDescription
            } else {
                self.alertTitle = "Success"
                self.alertMessage = "Successfully uploaded!"
                
                self.getProcessLoadImageLinks()
            }
        }
    }

    
    func deleteImage(row: Int) {
    
        let deleteHash = imagesViewModelArray[row].deletehash
    
        self.isLoading = true
        imgurAPIHelper.deleteImage(deleteHash: deleteHash) { (response, error) in
            self.isLoading = false
            if (error != nil) {
                self.alertTitle = "Error"
                self.alertMessage = error!.localizedDescription
            } else {
                self.alertTitle = "Success"
                self.alertMessage = "Successfully deleted image!"

                // this action should happen from the response, not back from here... e.g. removing an image from the server should automatically update the model, then
                // we can bid the update of the view model via a closure.
                
                self.imagesModelHelper.deleteImage(row: row)
            }
        }
    }
    
    
    public func getFullImgurImage(row: Int) {

        self.isLoading = true
        imgurAPIHelper.getFullImage(imageFilename: imagesViewModelArray[row].link) { (response, error) in
            self.isLoading = false
            if (error != nil) {
                self.alertTitle = "Error"
                self.alertMessage = error!.localizedDescription
            } else {
                if let response = response {
                    let image: UIImage? = response as? UIImage
                    self.imagesModelHelper.updateFullImage(row: row, image: image)
                }
            }
        }
    }
    
    
    // MARK: - Cell VIEWMODEL delivery to the VIEW
    
    // presents VIEWMODEL interface to collection view cell isolating the VIEW from logic outside of the VIEW
    func getCellViewModel(at row: Int) -> ImageCellViewModel {
        return imagesViewModelArray[row]
    }

}



