//
//  ImagesModel.swift
//  ImgurPlay
//
//  Created by Ken Streger on 5/27/18.
//  Copyright © 2018 Ken Streger. All rights reserved.
//

import UIKit


/* ******************************************************************************************************
 /
 /   The main data model used to contain the user's Imgur images information
 /
 /   More than the thin information set used in this app is stored, to make it simple for future
 /   expansion.
 /
 / ********************************************************************************************************
 */

var imagesArray: Array<ImgurImage> = []

struct ImgurImage {
    
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


