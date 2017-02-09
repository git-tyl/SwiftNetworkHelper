//
//  InternetHelper.swift
//  ConvertUnitsDark
//
//  Created by tyl on 25/6/16.
//  Copyright © 2016 strikespark. All rights reserved.
//

import Foundation


class NetworkHelper {
    
    struct ResponseCode {
        static let NoJSONData:Int = 700
        static let DifficultyParsingJSON:Int = 701
        static let ReturnedJSONButFailure:Int = 702
    }
    
    static let TimeOutInterval:Double = 10.0
    static let sharedInstance = NetworkHelper()
    //NSURLSession should be a long lived object that all created NSURLTask use
    //One NSURTask Per Request
    //more info on this WWDC 2013 session 705
    //therefore we create one singleton that will be used by all session task
    let session:NSURLSession
    
    init(){
        let sessionConfig = NSURLSessionConfiguration.defaultSessionConfiguration()
        sessionConfig.timeoutIntervalForRequest = NetworkHelper.TimeOutInterval
        sessionConfig.timeoutIntervalForResource = NetworkHelper.TimeOutInterval
        //http://www.drdobbs.com/architecture-and-design/memory-leaks-in-ios-7/240168600  stops any memory leaks
        sessionConfig.URLCache = NSURLCache(memoryCapacity: 0, diskCapacity: 0, diskPath: "URLCache")
        session = NSURLSession(configuration: sessionConfig)
    }

    static func createNSURLRequest(withString urlString:String, dataBody:AnyObject?, requestMethod:String, isJSON:Bool) -> NSMutableURLRequest?{
        
        let url:NSURL? = NSURL(string: urlString)
        
        let urlRequest:NSMutableURLRequest
        
        if let url = url {
            urlRequest = NSMutableURLRequest(URL:url)
        } else {
            print("DEBUG url string cannot be converted to url")
            return nil
        }
        
        if isJSON {
            urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
            if let dataBody:AnyObject = dataBody {
                if let dataBodyData = dataBody as? NSData {
                    urlRequest.HTTPBody = dataBodyData
                }
            }
        } else {
            urlRequest.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            if let dataBody:AnyObject = dataBody {
                urlRequest.HTTPBody = dataBody.dataUsingEncoding(NSUTF8StringEncoding)
            }
        }
        
        return urlRequest
    }
    
    static func request(mutableURLRequest mutableURLRequest:NSMutableURLRequest, success: (data:NSData?,response:NSURLResponse?,error:NSError?)->Void, failure: (data:NSData?,response:NSURLResponse?,error:NSError?, responseCode:Int)->Void){
        
        let dataTask:NSURLSessionDataTask = NetworkHelper.sharedInstance.session.dataTaskWithRequest(mutableURLRequest) { (dataInternal, responseInteral, errorInternal) in
            
            let HTTPResponse:NSHTTPURLResponse? = responseInteral as? NSHTTPURLResponse
            let responseCode:Int
            
            if let HTTPResponse:NSHTTPURLResponse = HTTPResponse {
                responseCode = HTTPResponse.statusCode
            } else {
                responseCode = 0
            }
            
            if  errorInternal != nil || responseCode != 200 {
                failure(data: dataInternal,response: responseInteral,error: errorInternal,responseCode: responseCode)
            } else {
                success(data: dataInternal, response:  responseInteral,error: errorInternal)
            }
        }
        
        dataTask.resume()
    }
    
//combination of two methods above
//This takes a urlstring that can either be a JSON or not
    static func request(urlString urlString:String, dataBody:AnyObject?, requestMethod:String, isJSON:Bool, success:(data:NSData?, response:NSURLResponse?, error:NSError?)->Void, failure:(data:NSData?, response:NSURLResponse?, error:NSError?, responseCode:Int)->Void){
        let urlRequst:NSMutableURLRequest? = createNSURLRequest(withString: urlString, dataBody: dataBody, requestMethod: requestMethod, isJSON: isJSON)
        
        if let urlRequst = urlRequst {
            request(mutableURLRequest: urlRequst, success: success, failure: failure)
        }
    }
    
    static func jsonBaseRequest(urlString urlString:String,dataBody:AnyObject?, requestMethod:String,  success:(json:AnyObject, response:NSURLResponse?, error:NSError?)->Void, failure:(json:AnyObject?, response:NSURLResponse?, error:NSError?, responseCode:Int)->Void){
        
        request(urlString:urlString,dataBody: dataBody,requestMethod:requestMethod,isJSON:true,
            success: {(dataInternal:NSData?, responseInternal:NSURLResponse?, errorInternal:NSError?)->Void in
                guard let dataInternal = dataInternal else {
                    failure(json:nil,response:responseInternal,error:nil,responseCode:ResponseCode.NoJSONData)
                    return
                }
                do {
                    let json:AnyObject = try NSJSONSerialization.JSONObjectWithData(dataInternal, options: .MutableContainers )
                    success(json:json, response: responseInternal, error: nil)
                } catch let JSONError as NSError{
                    failure(json:dataInternal,response: responseInternal,error: JSONError,responseCode: ResponseCode.DifficultyParsingJSON)
                    return
                }
            },
            failure: {(dataInternal:NSData?, responseInternal:NSURLResponse?, errorInternal:NSError?,responseCodeInternal:Int )->Void in
                guard let dataInternal = dataInternal else {
                    failure(json:nil,response:responseInternal,error:nil,responseCode:responseCodeInternal)
                    return
                }
                
                do {
                    let json:AnyObject = try NSJSONSerialization.JSONObjectWithData(dataInternal, options: .MutableContainers )
                    failure(json:json, response: responseInternal, error: nil,responseCode: responseCodeInternal)
                } catch let JSONError as NSError{
                    failure(json:nil,response: responseInternal,error: JSONError,responseCode: responseCodeInternal)
                    return
                }
            }
        )
    }
    
    static func jsonGetRequest(urlString urlString:String,success:(json:AnyObject, response:NSURLResponse?, error:NSError?)->Void, failure:(json:AnyObject?, response:NSURLResponse?, error:NSError?, responseCode:Int)->Void){
        jsonBaseRequest(urlString: urlString, dataBody: nil, requestMethod: "GET", success: success, failure: failure)
    }
    
    static func jsonPost(urlString urlString:String, databody:AnyObject?, success:(json:AnyObject, response:NSURLResponse?, error:NSError?)->Void, failure:(json:AnyObject?, response:NSURLResponse?, error:NSError?, responseCode:Int)->Void){
        jsonBaseRequest(urlString: urlString, dataBody: databody, requestMethod: "POST", success: success, failure: failure)
    }
    
    static func jsonDelete(urlString urlString:String, success:(json:AnyObject, response:NSURLResponse?, error:NSError?)->Void, failure:(json:AnyObject?, response:NSURLResponse?, error:NSError?, responseCode:Int)->Void){
        jsonBaseRequest(urlString: urlString, dataBody: nil, requestMethod: "DELETE", success: success, failure: failure)
    }
    
    //download
    
    static func download(){
        
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
}