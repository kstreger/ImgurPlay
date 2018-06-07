//
//  ImgurAPIHelper.swift
//  ImgurPlay
//
//  Created by Ken Streger on 5/27/18.
//  Copyright © 2018 Ken Streger. All rights reserved.
//

import Foundation

import AeroGearHttp
import AeroGearOAuth2


/* ******************************************************************************************************
/
/   All Imgur network requests for the app and direct http requests for images:
/
/   The Imgur API calls using AOuth2 are:
/         getImageLinks - returns an array of information for all user Imgur images
/         uploadImage - uses a binary image to add an image to the users Imgur images
/         deleteImage - uses deletehash to remove an Imgur image
/
/   Simple HTTP requests that do not use the Imgur API
/         getThumbnailImage - use the thumbnail link (image link with 'h' before filename extension)
/             to return an Imgur thumbnail image
/         getFullImage - use the image link to return the full Imgur image
/
/ ********************************************************************************************************
*/
 

public class ImgurAPIHelper {
    
    // Strings used for file access are set here for easy modification
    private let http = Http(baseURL: "https://api.imgur.com")
    
    private let kImageLinksPath = "/3/account/me/images"
    private let kImageUploadPath = "/3/image"
    private let kImageDeletePath = "/3/account/me/image/"
    
    private let kFullImageBaseURL = "https://i.imgur.com"
    private let kThumbnailImageBaseURL = "https://i.imgur.com"
    
    
    // Imgur config and Account module variables
    private var imgurConfig = ImgurConfig(clientId: kClientId, scopes:[])
    private lazy var gdModule = AccountManager.addImgurAccount(config: imgurConfig)


    
    public func getImageLinks(completionHandler: @escaping CompletionBlock) {

        http.authzModule = gdModule
        http.request(method: .get, path: kImageLinksPath,  parameters: nil, completionHandler: completionHandler)
    }
    
    
    
    public func getThumbnailImage(imageFilename: String, completionHandler: @escaping CompletionBlock) {
        
        let http2 = Http(baseURL: kThumbnailImageBaseURL,sessionConfig: URLSessionConfiguration.default, requestSerializer: HttpRequestSerializer(),
                         responseSerializer: ImgurResponseSerializer() )
        http2.request(method: .get, path: imageFilename,  parameters: nil, completionHandler: completionHandler)
    }
    
    
    
    public func getFullImage(imageFilename: String, completionHandler: @escaping CompletionBlock) {
        
        let http2 = Http(baseURL: kFullImageBaseURL,sessionConfig: URLSessionConfiguration.default, requestSerializer: HttpRequestSerializer(),
                         responseSerializer: ImgurResponseSerializer() )
        http2.request(method: .get, path: imageFilename,  parameters: nil, completionHandler: completionHandler)
    }
    
    
    
    public func uploadImage(imageData: Data, completionHandler: @escaping CompletionBlock) {

        http.authzModule = gdModule
        let multipartData = MultiPartData(data: imageData, name: "image", filename: "ImgurPlay", mimeType: "image/jpg")
        let multipartArray =  ["image": multipartData]
        http.request(method: .post, path: kImageUploadPath,  parameters: multipartArray, completionHandler: completionHandler)
    }
    
    
    
    public func deleteImage(deleteHash: String, completionHandler: @escaping CompletionBlock) {

        http.authzModule = gdModule
        http.request(method: .delete, path: "\(kImageDeletePath)\(deleteHash)",  parameters: nil, completionHandler: completionHandler)
    }
    
}




