//
//  ImgurPlayTests.swift
//  ImgurPlayTests
//
//  Created by Ken Streger on 5/23/18.
//  Copyright © 2018 Ken Streger. All rights reserved.
//

import XCTest
@testable import ImgurPlay

import AeroGearOAuth2

/*
/ ******************************************************************************************************************
/
/  This provides some unit tests as examples, but is not comprehensive. To run the tests for the API wrapper
/  functions, it is only necessary that the user has signed on once to gain an access token, which then becomes
/  available for all the tests.  A more extensive setup would be to have a separate test Imgur account where images
/  can be added and deleted without affecting any user.
/
/ ******************************************************************************************************************
*/

class ImgurPlayTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testConvertImageToData() {
        
        // test image and nil values as input
        
        var image = UIImage(named: "login")
        var data = Utilities.convertImageToData(image)
        
        XCTAssertNotNil(data, "Image was not converted to data")
        
        image = UIImage(named: "randomNonExistingImage")
        data = Utilities.convertImageToData(image)
        
        XCTAssertNil(data, "Nil Image not detected")
    }
    
    
    
    func testCreateImgurImageEntry() {
        
        // tests that nil values in are handled properly and output = input for non-nil values
        
        let link = "https://i.imgur.com/J08g1Eg.jpg"
        let name = ""
        let title = ""
        let type = "image/jpeg"
        let deletehash = "sIRhHjes13ZpkwG"
        let size = 452140
        let datetime = 1527612888
        let description = ""
        
        // stub typical valid response from Imgur read image info API
        var dataDict = [String: Any?]()
        
        dataDict["link"] = link
        dataDict["name"] = nil
        dataDict["title"] = nil
        dataDict["type"] = type
        dataDict["deletehash"] = deletehash
        dataDict["size"] = size
        dataDict["datetime"] = datetime
        dataDict["description"] = nil
        
        let imgurImage = createImgurImageEntry(imageDict: dataDict)
        
        var testPassed = false
        if imgurImage.link == link && imgurImage.name == name && imgurImage.title == title && imgurImage.type == type && imgurImage.deletehash == deletehash && imgurImage.size == size && imgurImage.datetime == datetime && imgurImage.description == description {
            testPassed = true
        }
        XCTAssert(testPassed, "Not all nils or non-nil values processed correctly")
    }
    
    
    func testValidateImageListResponse() {
        
        // create input expected, dictionary with key "data" containing an array of dictionaries:
        var dataDict = [String: Any?]()
        
        dataDict["link"] = "https://i.imgur.com/J08g1Eg.jpg"
        dataDict["type"] = "https://i.imgur.com/J08g1Eg.jpg"
        dataDict["deletehash"] = "sIRhHjes13ZpkwG"
        dataDict["size"] =  452140
        dataDict["datetime"] = 1527612888
        
        var array = [[String: Any?]]()
        array.append(dataDict)
        var dictResponse = [String: Any?]()
        dictResponse["data"] = array
        
        let vc = UIViewController()
        
        let (_, validation) = validateImageListResponse(dictResponse, vc: vc)
        
        XCTAssert(validation == .Success, "Input is not a dictionary containing an array of dictionaries")
    }
    
    
    func testGetFullImage() {

        let imgurAPIHelper = ImgurAPIHelper()
        let imageFileName = "http://sequelcreative.com/images/sequelLogo.png"

        let expectation = XCTestExpectation(description: "User getFullImage to download an image from a URL")

        imgurAPIHelper.getFullImage(imageFilename: imageFileName) {
            (response, error) in
            
            // Make sure we didn't get an error status
            XCTAssertNil(error, "Error code returned on getFullImage request")
            // Make sure we downloaded some data.
            XCTAssertNotNil(response, "No data was downloaded on getFullImage request.")
            // Make sure the response was an image
            XCTAssertNotNil(response as? UIImage, "Response was not properly converted to a UIImage")
            
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 10.0)

    }
    
    
    func testGetImageLinks() {
        
        // since the OAuth2 process requires login to get an access code, run the app once to enter credentials then you can
        // test all the OAuth2 wrappers calls.
        
        let expectation = XCTestExpectation(description: "User getFullImage to download an image from a URL")
        
        imgurAPIHelper.getImageLinks() { (response, error) in
            
            // Make sure we didn't get an error status
            XCTAssertNil(error, "Error code returned on getFullImage request")
            // Make sure we downloaded some data.
            XCTAssertNotNil(response, "No data was downloaded on getFullImage request.")
            // Fulfill the expectation to indicate that the background task has finished successfully.
            expectation.fulfill()
        }
        // Wait until the expectation is fulfilled, with a timeout of 10 seconds.
        wait(for: [expectation], timeout: 10.0)
    }
    
    func testAddImgurAccount() {
        
        let imgurConfig = ImgurConfig(clientId: kClientId, scopes:[])
        let gdModule = AccountManager.addImgurAccount(config: imgurConfig)
        
        XCTAssertNotNil(gdModule, "Could not create an Imgur Account")
    }
    


    
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
