//
//  Utilities.swift
//  ImgurPlay
//
//  Created by Ken Streger on 5/29/18.
//  Copyright © 2018 Ken Streger. All rights reserved.
//

import UIKit

    let compressionPercentage: CGFloat = 0.4



/* ******************************************************************************************************
 /
 /   Utilities - contains class methods that support common utility functions, including
 /          starting and stopping an activity indicator on a view controller
 /          and displaying an alert for error messages.
 /
 / ********************************************************************************************************
 */


public class Utilities {

    // Start, stop, hide and show the activity indicator
    
    class func startActivityIndicator(_ activityIndicatorView: UIActivityIndicatorView?) {
        guard let activityIndicator = activityIndicatorView else {
            return
        }
        activityIndicator.isHidden = false
        activityIndicator.startAnimating()
    }
    
    class func stopActivityIndicator(_ activityIndicatorView: UIActivityIndicatorView?) {
        guard let activityIndicator = activityIndicatorView else {
            return
        }
        activityIndicator.isHidden = true
        activityIndicator.stopAnimating()
    }
    
    
    
    // alert display for error messages
    
    class func displayMessage(_ title: String, message: String, vc: UIViewController) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        vc.present(alert, animated: true, completion: nil)
    }

    
    
    // returns a JPEG formatted data object from a UIImage
    
    class func convertImageToData(_ image: UIImage?) -> Data? {
        guard let image = image else {
            return nil
        }
        return  UIImageJPEGRepresentation(image, compressionPercentage) ?? Data()
    }

}








