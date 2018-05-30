//
//  ImgurOAuth2.swift
//  ImgurPlay
//
//  Created by Ken Streger on 5/25/18.
//  Copyright © 2018 Ken Streger. All rights reserved.
//

//import Foundation

import UIKit
import SafariServices
import AeroGearHttp
import AeroGearOAuth2


/* ******************************************************************************************************************
 /
 /   ImgurOAuth2: This subclass of the AeroGearOAuth2 OAuth2Module contains all the code specific to
 /       implementing OAuth2 for Imgur
 /
 /   There are several Imgur requirements that have been addressed.
 /      1. The flow of getting initial token access has been changed.  Typically for OAuth2, after creds
 /         are entered, an authorization code is used to retreive the token. For Imgur, the auth code
 /         is not used, and the access token, refresh token and expiration is sent immediately after
 /         credential verification.  This change in flow is captured in this subclass, primarily with
 /         the requestInitialToken method.
 /      2. The URL parameters have been modified in requestInitialToken to get initial access
 /      3. In requestInitialToken, the main view controller has been set up as the SFSafariViewController delegate.
 /         This is usedto control flow when the user aborts out of the Imgur login process'
 /      4. Extraction of the token information in tokenResponse contains changes as required by the Imgur response.
 /
 / ******************************************************************************************************************
 */


// This notification is sent from the App Delegate after a URI is received.
//It is observed here, and used to close the browser window in which the user entered credentials
public let kImgurURLNotification = "ImgurURLNotification"

public var accountUsername: String?
public var accountId: String?
public var tokenType: String?

/**
 The current state that this module is in.
 
 - AuthorizationStatePendingExternalApproval: the module is waiting external approval.
 - AuthorizationStateApproved: the oauth flow has been approved.
 - AuthorizationStateUnknown: the oauth flow is in unknown state (e.g. user clicked cancel).
 */
enum AuthorizationState {
    case authorizationStatePendingExternalApproval
    case authorizationStateApproved
    case authorizationStateUnknown
}


open class ImgurOAuth2: OAuth2Module{

    /**
     Parent class of any OAuth2 module implementing generic OAuth2 authorization flow.
     */
        /**
         Gateway to request authorization access.
         :param: completionHandler A block object to be executed when the request operation finishes.
         */
        
        var config: Config
        var applicationLaunchNotificationObserver: NSObjectProtocol?
        var applicationDidBecomeActiveNotificationObserver: NSObjectProtocol?
        var state: AuthorizationState
    
    
        /**
         Initialize an OAuth2 module for Imgur.
         
         :param: config the configuration object that setups the module.
         :param: session the session that that module will be bound to.
         :param: requestSerializer the actual request serializer to use when performing requests.
         :param: responseSerializer the actual response serializer to use upon receiving a response.
         
         :returns: the newly initialized ImgurOAuth2 instance.
         */
    
        public required init(config: Config, session: OAuth2Session? = nil, requestSerializer: RequestSerializer = HttpRequestSerializer(), responseSerializer: ResponseSerializer = JsonResponseSerializer()) {
            
            self.config = config
            self.state = .authorizationStateUnknown
            
            super.init(config: config, session: session, requestSerializer: requestSerializer, responseSerializer: responseSerializer)
            
            if (config.accountId == nil) {
                config.accountId = "ACCOUNT_FOR_CLIENTID_\(config.clientId)"
            }
            if (session == nil) {
                self.oauth2Session = TrustedPersistentOAuth2Session(accountId: config.accountId!)
            } else {
                self.oauth2Session = session!
            }
            self.config = config
            if config.webView == .embeddedWebView {
                self.webView = OAuth2WebViewController()
                self.customDismiss = true
            }
            if config.webView == .safariViewController {
                self.customDismiss = true
            }
            self.http = Http(baseURL: config.baseURL, requestSerializer: requestSerializer, responseSerializer:  responseSerializer)
        }
    
    
    // MARK: Public API - Overridden methods for specific Imgur OAuth2 processing
    
    /**
     Main driver to request token access.
     Typically an authorization code is returned and is used to request a token, but the Imgur OAuth2 process
     returns a token directly in place of the authorization code process.
     :param: completionHandler A block object to be executed when the request operation finishes.
     */
    override open func requestAccess(completionHandler: @escaping (AnyObject?, NSError?) -> Void) {
        if (self.oauth2Session.accessToken != nil && self.oauth2Session.tokenIsNotExpired()) {
            // we already have a valid access token, nothing more to be done
            completionHandler(self.oauth2Session.accessToken! as AnyObject?, nil)
        } else if (self.oauth2Session.refreshToken != nil && self.oauth2Session.refreshTokenIsNotExpired()) {
            // need to refresh token
            self.refreshAccessToken(completionHandler: completionHandler)
        } else {
            // ask for initial access token
            self.requestInitialToken(completionHandler: completionHandler)
        }
    }
    

    
    

    // The Imgur OAuth2 process dispenses with the typical flow of using an authorization code to retreive an access token
    // This method reflects these changes.

    open func requestInitialToken(completionHandler: @escaping (AnyObject?, NSError?) -> Void) {
            // register with the notification system in order to be notified when the 'authorization of credentials' process completes in the
            // browser, and the oauth access token is available to extract
            applicationLaunchNotificationObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: kImgurURLNotification), object: nil, queue: nil, using: { (notification: Notification!) -> Void in
                self.extractTokens(notification, completionHandler: completionHandler)
                if ( self.webView != nil || self.customDismiss) {
                    UIApplication.shared.keyWindow?.rootViewController?.dismiss(animated: true, completion: nil)
                }
            })
            
            // register to receive notification when the application becomes active so we
            // can clear any pending authorization requests which are not completed properly,
            // that is a user switched into the app without Accepting or Cancelling the authorization
            // request in the external browser process.
            applicationDidBecomeActiveNotificationObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: AGAppDidBecomeActiveNotification), object:nil, queue:nil, using: { (note: Notification!) -> Void in
                // check the state
                if (self.state == .authorizationStatePendingExternalApproval) {
                    // unregister
                    self.stopObserving()
                    // ..and update state
                    self.state = .authorizationStateUnknown
                }
            })
            
            // update state to 'Pending'
            self.state = .authorizationStatePendingExternalApproval

            // calculate final url
            // ****  Modify for Imgur requirements ****
            var params = "?client_id=\(config.clientId)&response_type=token"
            
            if let audienceId = config.audienceId {
                params = "\(params)&audience=\(audienceId)"
            }
            
            guard let computedUrl = http.calculateURL(baseURL: config.baseURL, url: config.authzEndpoint) else {
                let error = NSError(domain:AGAuthzErrorDomain, code:0, userInfo:["NSLocalizedDescriptionKey": "Malformatted URL."])
                completionHandler(nil, error)
                return
            }
            
            if let url = URL(string:computedUrl.absoluteString + params) {
                switch config.webView {
                case .embeddedWebView:
                    if self.webView != nil {
                        config.webViewHandler(self.webView!, completionHandler)
                    }
                case .externalSafari:
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                case .safariViewController:
                    // ****  Set the main ViewController as the delegate for SFSafariViewController ****
                    // ****  This provides control for when the user aborts out of the login process ****
                    let safariController = SFSafariViewController(url: url)
                    let appDelegate = UIApplication.shared.delegate as! AppDelegate
                    safariController.delegate = appDelegate.mainViewController
                    config.webViewHandler(safariController, completionHandler)
                }
            }
        }
    
    
    
        // Imgur processing to extract the access and refresh tokens, expiration and account id and username
        // Some minor changes here to properly parse the Imgur response
        override open func tokenResponse(_ unwrappedResponse: [String: AnyObject]) -> String {
            let accessToken: String   = unwrappedResponse["access_token"] as! String
            let refreshToken: String? = unwrappedResponse["refresh_token"] as? String
            let idToken: String?      = unwrappedResponse["id_token"] as? String
            let serverCode: String?   = unwrappedResponse["server_code"] as? String
            let exp: String?          = unwrappedResponse["expires_in"] as? String
            // expiration for refresh token is used in Keycloak
            let expirationRefresh     = unwrappedResponse["refresh_expires_in"] as? NSNumber
            let expRefresh            = expirationRefresh?.stringValue
            accountId                 = unwrappedResponse["account_id"] as? String
            accountUsername           = unwrappedResponse["account_username"] as? String
            tokenType                 = unwrappedResponse["token_type"] as? String
            
            self.oauth2Session.save(accessToken: accessToken, refreshToken: refreshToken, accessTokenExpiration: exp, refreshTokenExpiration: expRefresh, idToken: idToken)
            self.idToken    = self.oauth2Session.idToken
            self.serverCode = serverCode
            
            return accessToken
        }
    
    
    
    
    // MARK: Internal Methods - same processing as parent class.
    
    func extractTokens(_ notification: Notification, completionHandler: @escaping (AnyObject?, NSError?) -> Void) {
        let info = notification.userInfo!
        guard let url = info[UIApplicationLaunchOptionsKey.url] as? URL else {
            let error = NSError(domain:AGAuthzErrorDomain, code:0, userInfo:["NSLocalizedDescriptionKey": "No data returned to application."])
            completionHandler(nil, error)
            return
        }

        // split by "#" to separate parameters from request.  Parse into [key:value] dictionary
        // Should be two parts, base url and everything after # including params

        let urlComponentArray = url.absoluteString.components(separatedBy:"#")
        if urlComponentArray.count < 2 {
            let error = NSError(domain:AGAuthzErrorDomain, code:0, userInfo:["NSLocalizedDescriptionKey": "Access denied."])
            completionHandler(nil, error)
            return
        }

        var paramDict = [String:Any]()
        let paramArray:[String] = urlComponentArray[1].components(separatedBy:"&")
        for paramPair in paramArray {
            let paramElements = paramPair.components(separatedBy: "=")
            paramDict[paramElements[0]] = paramElements[1]
        }

        let accessToken = self.tokenResponse(paramDict as [String : AnyObject])
        completionHandler(accessToken as AnyObject?, nil)

        // finally, unregister
        self.stopObserving()
    }
    
        
        func parametersFrom(queryString: String?) -> [String: String] {
            var parameters = [String: String]()
            if (queryString != nil) {
                let parameterScanner: Scanner = Scanner(string: queryString!)
                var name: NSString? = nil
                var value: NSString? = nil
                
                while (parameterScanner.isAtEnd != true) {
                    name = nil
                    parameterScanner.scanUpTo("=", into: &name)
                    parameterScanner.scanString("=", into:nil)
                    
                    value = nil
                    parameterScanner.scanUpTo("&", into:&value)
                    parameterScanner.scanString("&", into:nil)
                    
                    if (name != nil && value != nil) {
                        parameters[name!.removingPercentEncoding!] = value!.removingPercentEncoding
                    }
                }
            }
            
            return parameters
        }
    
    
        deinit {
            self.stopObserving()
        }

    
        func stopObserving() {
            // clear all observers
            if (applicationLaunchNotificationObserver != nil) {
                NotificationCenter.default.removeObserver(applicationLaunchNotificationObserver!)
                self.applicationLaunchNotificationObserver = nil
            }
            
            if (applicationDidBecomeActiveNotificationObserver != nil) {
                NotificationCenter.default.removeObserver(applicationDidBecomeActiveNotificationObserver!)
                applicationDidBecomeActiveNotificationObserver = nil
            }
        }
    }

