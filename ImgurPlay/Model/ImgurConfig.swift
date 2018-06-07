//
//  ImgurConfig.swift
//  ImgurPlay
//
//  Created by Ken Streger on 5/27/18.
//  Copyright © 2018 Ken Streger. All rights reserved.
//

import Foundation

import AeroGearHttp
import AeroGearOAuth2


// App Client Id and Secret, used for Imgur API config
public let kClientId = "6a75ead9a059c92"
public let kClientSecret = "a79d34abcc0c5c71a336b5f5973de912cd5c2922"



/* ******************************************************************************************************
 /
 /   ImgurConfig adds the Imgur API configuration endpoints used in the authorization process.
 /
 / ********************************************************************************************************
 */



/**
 A Config object that setups Google specific configuration parameters.
 */
open class ImgurConfig: Config {
    
    private let browserType = WebViewType.safariViewController
    
    /**
     Init a Imgur configuration.
     :param: clientId OAuth2 credentials an unique string that is generated in the OAuth2 provider Developers Console.
     :param: scopes an array of scopes the app is asking access to.
     :param: accountId this unique id is used by AccountManager to identify the OAuth2 client.
     :param: isOpenIDConnect to identify if fetching id information is required.
     */
    public init(clientId: String, scopes: [String], audienceId: String? = nil, accountId: String? = nil, isOpenIDConnect: Bool = false) {
        
        super.init(base: "https://api.imgur.com",
                   authzEndpoint: "/oauth2/authorize",
                   redirectURL: "ImgurPlay://request",
                   accessTokenEndpoint: "/oauth2/token",
                   clientId: clientId,
                   audienceId: audienceId,
                   refreshTokenEndpoint: "/oauth2/token",
                   revokeTokenEndpoint: "/oauth2/revoke",
                   isOpenIDConnect: isOpenIDConnect,
                   scopes: scopes,
                   clientSecret: kClientSecret,
                   accountId: accountId
        )
        
        self.webView = browserType
        // Add openIdConnect scope
        if self.isOpenIDConnect {
            self.scopes += ["openid", "email", "profile"]
        }
    }
}


extension AccountManager {
    
    class func addImgurAccount(config: ImgurConfig) -> ImgurOAuth2 {
        var myModule: ImgurOAuth2
        myModule = addAccountWith(config: config, moduleClass: ImgurOAuth2.self) as! ImgurOAuth2
        return myModule
    }
}
