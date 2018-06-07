//
//  ImagePickerController.swift
//  ImgurPlay
//
//  Created by Ken Streger on 6/1/18.
//  Copyright © 2018 Ken Streger. All rights reserved.
//

import UIKit

/* ******************************************************************************************************
 /
 /   The ImagePickerController houses the delegates to process the image selected to upload it
 /   to the Imgur server.  The user action captured here and invoked in the parent view controller
 /   (ViewController).
 /
 / ******************************************************************************************************
 */

class ImagePickerController: UIImagePickerController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    var parentVC: ViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // if an image is selected from the image picker using the Photo Library, save it in a local image for uploading, and bid the process to upload
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        guard let parentVC = parentVC else {
            return
        }
        
        parentVC.imageView.image = info[UIImagePickerControllerOriginalImage] as? UIImage
        self.dismiss(animated: true, completion: nil)

        DispatchQueue.main.async {
            parentVC.uploadImage()
        }
    }
    
    // User canceled out of image picker using the Photo Library - dismiss controller
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {

        self.dismiss(animated: true, completion: nil)
    }

}
