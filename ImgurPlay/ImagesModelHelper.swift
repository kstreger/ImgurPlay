//
//  ImagesModelHelper.swift
//  ImgurPlay
//
//  Created by Ken Streger on 5/29/18.
//  Copyright © 2018 Ken Streger. All rights reserved.
//

import UIKit


/* ********************************************************************************************************
 /
 /   Helper functions to store data received from Imgur API into the data model
 /
 / ********************************************************************************************************
 */

let imgurAPIHelper = ImgurAPIHelper()

enum ValidationResult {
    case Success
    case Invalid
}


class ImagesModelHelper {

    // Drives process to parse images response and load into the model

    public func addDictEntryToModel(imageDict:  [String : Any?]) {
        let imgurImage = createImgurImageEntry(imageDict:  imageDict)
        imagesArray.append(imgurImage)
    }


    // Helper function to parse the images info response

    public func createImgurImageEntry(imageDict:  [String : Any?]) -> ImgurImage {
        let link = imageDict["link"] as! String? ?? ""
        var thumbnailLink: String = link
        if thumbnailLink != "" {
            let pos = thumbnailLink.range(of:".", options:.backwards)?.lowerBound
            thumbnailLink.insert("h", at: pos!)
        }
        let name = (imageDict["name"] as? String? ?? "") ?? ""
        let title = (imageDict["title"] as? String? ?? "") ?? ""
        let type = (imageDict["type"] as? String? ?? "") ?? ""
        let deletehash = (imageDict["deletehash"] as? String? ?? "") ?? ""
        let size = (imageDict["size"] as? Int? ?? 0) ?? 0
        let datetime = (imageDict["datetime"] as? Int? ?? 0) ?? 0
        let description = (imageDict["description"] as? String? ?? "") ?? ""
    
        let imgurImage = ImgurImage(name: name, title: title, description: description, type: type, size: size, datetime: datetime, link: link, thumbnailLink: thumbnailLink, deletehash: deletehash)
    
        return imgurImage
    }



    // Validates the response from the image list read, and returns an Array of Dictionary objects or an error status

    public func validateImageListResponse(_ response: Any?, vc: UIViewController) -> (Array<[String:Any?]>, ValidationResult) {
        let responseDict = response as! Dictionary<String, Any>
        guard let dataDict = responseDict["data"] else {
            Utilities.displayMessage("Error", message: "No data returned", vc: vc)
            return ([[String: Any?]](), .Invalid)
        }
        guard let imageResponseArray = dataDict as? Array<[String:Any?]> else {
            Utilities.displayMessage("Error", message: "No data returned", vc: vc)
            return ([[String: Any?]](), .Invalid)
        }
        return (imageResponseArray, .Success)
    }

}





