//
//  ImagesViewModelHelper.swift
//  ImgurPlay
//
//  Created by Ken Streger on 5/29/18.
//  Copyright © 2018 Ken Streger. All rights reserved.
//

import UIKit


/* ********************************************************************************************************
 /
 /   The ImagesViewModelHelper contains methods to update the VIEWMODEL from the MODEL
 /
 / ********************************************************************************************************
 */


class ImagesViewModelHelper {

    public func updateViewModel() -> [ImageCellViewModel] {
        
        var workViewModel = [ImageCellViewModel]()
        for modelEntry in imagesArray {
            
            let workViewModelEntry = ImageCellViewModel(name: modelEntry.name, title: modelEntry.title, description: modelEntry.description, type: modelEntry.type, size: modelEntry.size, datetime: modelEntry.datetime, link: modelEntry.link, thumbnailLink: modelEntry.thumbnailLink, deletehash: modelEntry.deletehash)
            
            workViewModel.append(workViewModelEntry)
        }
        return workViewModel
    }



    public func updateViewModelThumbnail() -> [ImageCellViewModel] {
    
        var workViewModel = [ImageCellViewModel]()
        for modelEntry in imagesArray {
        
            var workViewModelEntry = ImageCellViewModel(name: modelEntry.name, title: modelEntry.title, description: modelEntry.description, type: modelEntry.type, size: modelEntry.size, datetime: modelEntry.datetime, link: modelEntry.link, thumbnailLink: modelEntry.thumbnailLink, deletehash: modelEntry.deletehash)
            workViewModelEntry.thumbnailImage = modelEntry.thumbnailImage
        
            workViewModel.append(workViewModelEntry)
        }
        return workViewModel
    }
    
    
    public func updateViewModelImage(index: Int) -> UIImage? {
        return imagesArray[index].image
    }

}






