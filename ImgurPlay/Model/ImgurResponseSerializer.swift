//
//  ImgurResponseSerializer.swift
//  ImgurPlay
//
//  Created by Ken Streger on 5/25/18.
//  Copyright © 2018 Ken Streger. All rights reserved.
//

import Foundation

import AeroGearHttp

/* ******************************************************************************************************
 /
 /   This subclass of the AeroGearHttp response serializer performs only one function:
 /
 /          convert the data response as a UIImage
 /
 / ********************************************************************************************************
*/

public class ImgurResponseSerializer: ResponseSerializer {

        // convert the data response to a UIImage
        open var response: (Data, Int) -> Any? = {(data: Data, status: Int) -> (Any?) in
            return UIImage(data: data)
        }
        
        /**
         Validate the response received.
         
         :returns:  either true or false if the response is valid for this particular serializer.
         */
        open var validation: (URLResponse?, Data) throws -> Void = { (response: URLResponse?, data: Data) throws in
            var error: NSError! = NSError(domain: HttpErrorDomain, code: 0, userInfo: nil)
            let httpResponse = response as! HTTPURLResponse
            
            if !(httpResponse.statusCode >= 200 && httpResponse.statusCode < 300) {
                let userInfo = [
                    NSLocalizedDescriptionKey: HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode),
                    NetworkingOperationFailingURLResponseErrorKey: response ?? "HttpErrorDomain"] as [String : Any]
                error = NSError(domain: HttpResponseSerializationErrorDomain, code: httpResponse.statusCode, userInfo: userInfo)
                throw error
            }
        }
        
        public init() {
        }
        
        public init(validation: @escaping (URLResponse?, Data) throws -> Void, response: @escaping (Data, Int) -> AnyObject?) {
            self.validation = validation
            self.response = response
        }
        
        public init(validation: @escaping (URLResponse?, Data) throws -> Void) {
            self.validation = validation
        }
        
        public init(response: @escaping (Data, Int) -> AnyObject?) {
            self.response = response
        }
}
