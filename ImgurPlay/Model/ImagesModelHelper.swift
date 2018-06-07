//
//  ImagesModelHelper.swift
//  ImgurPlay
//
//  Created by Ken Streger on 6/6/18.
//  Copyright © 2018 Ken Streger. All rights reserved.
//

import UIKit


/* ********************************************************************************************************
 /
 /   The ImagesViewModelHelper contains methods to load the MODEL from the Imgur API.
 /
 / ********************************************************************************************************
 */


enum ValidationResult {
    case Success
    case Invalid
}


class ImagesModelHelper {

    let imgurAPIHelper = ImgurAPIHelper()
    
    // MARK: - Refresh entire MODEL processing

// drives the process to load the image api response into the database and load associated thumbnail images

    func parseImageList(response: Any?) -> ValidationResult {
    
        let (imageResponseArray, validation) = validateImageListResponse(response)
        if validation == .Invalid {
            return validation
        }
    
        imagesArray = loadModel(imageResponseArray)   // model is refreshed
        modelUpdated = true                           // kicks off updated closure to update the viewModel

        for index in 0...imagesArray.count-1 {
            loadThumbnailImage(index: index)
        }
        return .Success
    }
    
    
    // Validates the response from the image list read, and returns an Array of Dictionary objects or an error status
    
    public func validateImageListResponse(_ response: Any?) -> (Array<[String:Any?]>, ValidationResult) {
        
        let responseDict = response as! Dictionary<String, Any>
        guard let dataDict = responseDict["data"] else {
            return ([[String: Any?]](), .Invalid)
        }
        guard let imageResponseArray = dataDict as? Array<[String:Any?]> else {
            return ([[String: Any?]](), .Invalid)
        }
        return (imageResponseArray, .Success)
    }
    
    
    
    func loadModel(_ imageResponseArray: [[String : Any?]]) -> [ImgurImage] {
        
        var workModel = [ImgurImage]()
        for (_, responseDict) in imageResponseArray.enumerated() {
            let imagesModelEntry = createModelEntry(responseDict: responseDict)
            workModel.append(imagesModelEntry)
        }
        return workModel
    }
    
    
    public func createModelEntry(responseDict:  [String : Any?]) -> ImgurImage {
        let imagesModelEntry = createImagesModelEntry(responseDict:  responseDict)
        return imagesModelEntry
    }

    // Helper function to parse the images info response
    
    public func createImagesModelEntry(responseDict:  [String : Any?]) -> ImgurImage {
        let link = responseDict["link"] as! String? ?? ""
        var thumbnailLink: String = link
        if thumbnailLink != "" {
            let pos = thumbnailLink.range(of:".", options:.backwards)?.lowerBound
            thumbnailLink.insert("h", at: pos!)
        }
        let name = (responseDict["name"] as? String? ?? "") ?? ""
        let title = (responseDict["title"] as? String? ?? "") ?? ""
        let type = (responseDict["type"] as? String? ?? "") ?? ""
        let deletehash = (responseDict["deletehash"] as? String? ?? "") ?? ""
        let size = (responseDict["size"] as? Int? ?? 0) ?? 0
        let datetime = (responseDict["datetime"] as? Int? ?? 0) ?? 0
        let description = (responseDict["description"] as? String? ?? "") ?? ""
        
        let imagesModelEntry = ImgurImage(name: name, title: title, description: description, type: type, size: size, datetime: datetime, link: link, thumbnailLink: thumbnailLink, deletehash: deletehash)
        
        return imagesModelEntry
    }
    
    
    
    // MARK: - Update MODEL entry - thumbnail processing
    
    
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
                // skip this one without alert and continue after writing error to console
                print("Error loading thumbnail for model row: \(index) - \(imagesArray[index].thumbnailLink)")
            } else {
                if let response = response {
                    imagesArray[index].thumbnailImage = response as? UIImage
                    modelEntryThumbnailUpdated = true
                }
            }
        }
    }
    
    
    // MARK: - Delete MODEL entry processing
    
    
    public func deleteImage(row: Int) {
        imagesArray.remove(at: row)
        modelEntryDeleted = row         // triggers closure to update viewModel as per its requirements
}
    
    
    // MARK: - Update MODEL entry - image processing
    
    
    public func updateFullImage(row: Int, image: UIImage?) {
        imagesArray[row].image = image
        modelEntryImageUpdated = row
    }



}

