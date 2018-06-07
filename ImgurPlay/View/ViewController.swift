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
//     - Setup the closures that will be triggered by the changes in variables in the VIEWMODEL, to perform the VIEW
//       requirements.
//     - Captures and drives 'Login'(retry) and 'Add Images' button actions (The touches on the collection view cell
//       are captured and processed in the CollectionViewCell
//     - Sets up a gestureRecognizer for the ImageView where a full screen image had been displayed. The touch gesture
//       hides the image.
//     - Contains an extension for the Safari window delegate used in Login authorization processing
//
// **********************************************************************************************************************

class ViewController: UIViewController, UINavigationControllerDelegate {
    
    // MARK: - Instance properties

    public let imagesViewModelHelper = ImagesViewModelHelper()

    // Used to access the user Photo Library
    public var imagePicker = ImagePickerController()
    
    // The imageView UI property is used to display the selected collection cell thumbnail as
    // the user requests a full screen view from the view button in the CollectionViewCell
    @IBOutlet weak public var imageView: UIImageView!
    @IBOutlet weak private var loginButton: UIButton!
    @IBOutlet weak public var activityIndicatorView: UIActivityIndicatorView!

    lazy var viewModel: ImagesViewModel = {
        return ImagesViewModel()
    }()
    
    // MARK: - Initialization, View, and Closure Setup
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.mainViewController = self

        // setup the imageView for use in displaying full screen
        // This and the login button are only views directly managed by this View Controller
        setUpTapGestureForImageView()
        Utilities.stopActivityIndicator(activityIndicatorView)
        
        // This app uses closures triggered on variable changes to keep the VIEW-VIEWMODEL-MODEL independent
        // Setup the closures that will be triggered by the changes in variables in the VIEWMODEL,
        // to perform the VIEW requirements.
        // For example, when the VIEWMODEL has data available, this 'notifies' the VIEW to perform what
        // it needs.
        setupViewClosures()
        
        // ask view model for data to display
        DispatchQueue.main.async {
            self.viewModel.getProcessLoadImageLinks()
        }
    }
    
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    // Establishes Tap Gesture to close the full screen image displauy
    private func setUpTapGestureForImageView() {
        let singleTapGesture: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didSingleTapFullImage(_:)))
        singleTapGesture.numberOfTapsRequired = 1
        self.imageView.addGestureRecognizer(singleTapGesture)
        self.imageView.alpha = 0.0
    }
    
    
    // Setup the closures that will be triggered by the changes in variables in the VIEWMODEL,
    // to perform the VIEW requirements.
    func setupViewClosures() {

        viewModel.showAlertClosure = { [weak self] () in
            DispatchQueue.main.async {
                if let title = self?.viewModel.alertTitle, let message = self?.viewModel.alertMessage  {
                    Utilities.displayMessage(title, message: message, vc: self!)
                }
            }
        }
        
        viewModel.updateLoadingStatus = { [weak self] () in
            DispatchQueue.main.async {
                let isLoading = self?.viewModel.isLoading ?? false
                if isLoading {
                    Utilities.startActivityIndicator(self?.activityIndicatorView)
                } else {
                    Utilities.stopActivityIndicator(self?.activityIndicatorView)
                }
            }
        }
        
        viewModel.reloadTableViewClosure = { [weak self] () in
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: Notification.Name(rawValue: kReloadNotification), object: self)
                self?.loginButton.isHidden = true
            }
        }
        
        
        viewModel.fullImageClosure = { [weak self] (image: UIImage?) in
            DispatchQueue.main.async {
                self?.showFullImage(image: self?.viewModel.fullImage)
            }
        }
    }
    
    // MARK: - Button and Gesture Actions

    // The login action is only explicitly bid by the user if the login had previously been aborted by the user.
    // The action requests the collection view to be loaded (downloading the image info of the user)
    // and the initial login and access token is a byproduct of that request
    
    // Need to decouple from View Controller
    @IBAction private func retryLogin(_ sender: AnyObject) {
        viewModel.getProcessLoadImageLinks()
    }

    
    // addImages is bid from the "Add Images" button.  It opens the Photo Library in an image picker after checking authorizations
    // After the user enters the Photo Library to select the image to upload, all further processing
    // is handled by the image picker delegate and the uploadImage method
    
    @IBAction private func addImages(_ sender: AnyObject) {
        
        weak var weakSelf = self
        
        let photos = PHPhotoLibrary.authorizationStatus()
        if photos == .notDetermined {
            PHPhotoLibrary.requestAuthorization({status in
                if status == .authorized{
                    self.imagePicker.sourceType = .photoLibrary
                    self.imagePicker.delegate = self.imagePicker
                    self.imagePicker.parentVC = weakSelf
                    self.present(self.imagePicker, animated: true, completion: nil)
                }
            })
        } else {
            if photos == .authorized {
                imagePicker.sourceType = .photoLibrary
                imagePicker.delegate = self.imagePicker
                imagePicker.parentVC = weakSelf
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
    
    
    // driven from the UIImagePickerController delegate after a user selects an image from the Photo Library
    
    func uploadImage() {
        
        guard let imageData = Utilities.convertImageToData(imageView.image) else {
            Utilities.displayMessage("Error Converting Image to Data", message: "Select an image to upload first.", vc: self)
            return
        }
        
        viewModel.uploadImage(imageData: imageData)
    }


    // MARK: - Image View Action
    
    // Bid from the collection cell when the user touches the view icon
    
    public func showFullImage(image: UIImage?) {
        
        guard let image = image else {
            return
        }
        imageView.image = image
        self.view.bringSubview(toFront: imageView)
        UIView.animate(withDuration: 0.75, animations: {
            self.imageView.alpha = 1.0
        })
    }
}



// MARK: - Safari Login Delegate

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


