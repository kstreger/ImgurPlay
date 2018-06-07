# ImgurPlay

## MVVM Architecture
This version refactors the code to use the Model-View-ViewModel pattern.  

The VIEW, MODEL, and VIEWMODEL are completely decoupled.

In this app, bindings are created using simple closures, executed when state properties are set reflecting changes in the data models. 

For example, an update to the VIEWMODEL changes a property in the VIEWMODEL associated with a closure that is set by the VIEW.  In this way, VIEW responsibilities are invoked by the VIEWMODEL changes, without the VIEWMODEL knowing anything about the actions that the VIEWMODEL update has triggered.


## Project Requirements

ImgurPlay fufills the following requirements: 

* Integrates with imgur’s OAuth2 Authorization for login
* Has the ability to upload images
* You can view all images associated with an imgur account
* You can delete images from an
imgurAccount
* It uses the AeroGearOAuth2 library and the AeroGearHttp library


## How it works

#### 1. Open the app for the first time and it will invoke the imgur login screen. After username and password are entered, the user’s imgur images are displayed in a collection view.

#### 2. Upload new images by using the Add Images button


#### 3. Select an image cell to display the View and Delete icons.
- The view icon retrieves the full size version of the image as uploaded to the imgur account. Touching the full size display returns to the collection of images.

- The view icon retrieves the full size version of the image as uploaded to the imgur account

> **NOTE:**  See Outstanding Bugs later in this Readme file.



## Installation
The download comes with the AeroGearOAuth2 and AeroGearHttp libraries installed with [Cocoapods](http://cocoapods.org).  It should run it without installing Cocoapods or updating the libraries. Open ImgurPlay.xcworkspace to run in XCode.

To update the libraries, install [cocoapods](http://blog.cocoapods.org/CocoaPods-0.36/) and then install the pod. On the root directory of the project run:

```
pod install
```

You can update libraries with.

```
pod update
```

## Documentation

Each separate class is documented at the top of the file and the purpose of most methods are defined in comments.

## Unit Tests

Some different examples of unit tests have been written and are included. Due to time constraints, the test suite is not nearly exhaustive. I’ve chosen to write several different types of methods in the app as a demonstration.

## Questions?

Email me at: kstreger@optonline.net

## Outstanding Bugs

1. Rapid and repeating touches on buttons may produce undesirable results.

> **NOTE:**  Some minor improvements would be desirable. See Suggested Improvements, later in this Readme file.

## Suggested Improvements

1. The Add Images process can be made more efficient.  It currently sends an new image to Imgur server, and then reloads the entire app model. An improvement would be to only load the new image information from the server, and download only a single thumbnail.
