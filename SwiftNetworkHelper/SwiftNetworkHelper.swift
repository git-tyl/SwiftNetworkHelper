//
//  InternetHelper.swift
//  ConvertUnitsDark
//
//  Created by tyl on 25/6/16.
//  Copyright © 2016 strikespark. All rights reserved.
//

import Foundation
//updated for swift 3

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
    let session:URLSession
    
    init(){
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = NetworkHelper.TimeOutInterval
        sessionConfig.timeoutIntervalForResource = NetworkHelper.TimeOutInterval
        //http://www.drdobbs.com/architecture-and-design/memory-leaks-in-ios-7/240168600  stops any memory leaks
        sessionConfig.urlCache = URLCache(memoryCapacity: 0, diskCapacity: 0, diskPath: "URLCache")
        session = URLSession(configuration: sessionConfig)
    }

    static func createNSURLRequest(withString urlString:String, dataBody:AnyObject?, requestMethod:String, isJSON:Bool) -> NSMutableURLRequest?{
        
        let url:URL? = URL(string: urlString)
        
        let urlRequest:NSMutableURLRequest
        
        if let url = url {
            urlRequest = NSMutableURLRequest(url:url)
        } else {
            print("DEBUG url string cannot be converted to url")
            return nil
        }
        
        if isJSON {
            urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
            if let dataBody:AnyObject = dataBody {
                if let dataBodyData = dataBody as? Data {
                    urlRequest.httpBody = dataBodyData
                }
            }
        } else {
            urlRequest.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            if let dataBody:AnyObject = dataBody {
                urlRequest.httpBody = dataBody.data(using: String.Encoding.utf8)
            }
        }
        
        return urlRequest
    }
    
    static func request(mutableURLRequest:NSMutableURLRequest, success: @escaping (_ data:Data?,_ response:URLResponse?,_ error:NSError?)->Void, failure: @escaping (_ data:Data?,_ response:URLResponse?,_ error:NSError?, _ responseCode:Int)->Void){
        
        let dataTask:URLSessionDataTask = NetworkHelper.sharedInstance.session.dataTask(with: mutableURLRequest, completionHandler: { (dataInternal, responseInteral, errorInternal) in
            
            let HTTPResponse:HTTPURLResponse? = responseInteral as? HTTPURLResponse
            let responseCode:Int
            
            if let HTTPResponse:HTTPURLResponse = HTTPResponse {
                responseCode = HTTPResponse.statusCode
            } else {
                responseCode = 0
            }
            
            if  errorInternal != nil || responseCode != 200 {
                failure(data: dataInternal,response: responseInteral,error: errorInternal,responseCode: responseCode)
            } else {
                success(data: dataInternal, response:  responseInteral,error: errorInternal)
            }
        }) 
        
        dataTask.resume()
    }
    
//combination of two methods above
//This takes a urlstring that can either be a JSON or not
    static func request(urlString:String, dataBody:AnyObject?, requestMethod:String, isJSON:Bool, success:@escaping (_ data:Data?, _ response:URLResponse?, _ error:NSError?)->Void, failure:@escaping (_ data:Data?, _ response:URLResponse?, _ error:NSError?, _ responseCode:Int)->Void){
        let urlRequst:NSMutableURLRequest? = createNSURLRequest(withString: urlString, dataBody: dataBody, requestMethod: requestMethod, isJSON: isJSON)
        
        if let urlRequst = urlRequst {
            request(mutableURLRequest: urlRequst, success: success, failure: failure)
        }
    }
    
    static func jsonBaseRequest(urlString:String,dataBody:AnyObject?, requestMethod:String,  success:@escaping (_ json:AnyObject, _ response:URLResponse?, _ error:NSError?)->Void, failure:@escaping (_ json:AnyObject?, _ response:URLResponse?, _ error:NSError?, _ responseCode:Int)->Void){
        
        request(urlString:urlString,dataBody: dataBody,requestMethod:requestMethod,isJSON:true,
            success: {(dataInternal:Data?, responseInternal:URLResponse?, errorInternal:NSError?)->Void in
                guard let dataInternal = dataInternal else {
                    failure(nil,responseInternal,nil,ResponseCode.NoJSONData)
                    return
                }
                do {
                    let json:AnyObject = try JSONSerialization.jsonObject(with: dataInternal, options: .mutableContainers )
                    success(json, responseInternal, nil)
                } catch let JSONError as NSError{
                    failure(dataInternal as AnyObject?,responseInternal,JSONError,ResponseCode.DifficultyParsingJSON)
                    return
                }
            },
            failure: {(dataInternal:Data?, responseInternal:URLResponse?, errorInternal:NSError?,responseCodeInternal:Int )->Void in
                guard let dataInternal = dataInternal else {
                    failure(nil,responseInternal,nil,responseCodeInternal)
                    return
                }
                
                do {
                    let json:AnyObject = try JSONSerialization.jsonObject(with: dataInternal, options: .mutableContainers )
                    failure(json, responseInternal, nil,responseCodeInternal)
                } catch let JSONError as NSError{
                    failure(nil,responseInternal,JSONError,responseCodeInternal)
                    return
                }
            }
        )
    }
    
    static func jsonGetRequest(urlString:String,success:@escaping (_ json:AnyObject, _ response:URLResponse?, _ error:NSError?)->Void, failure:@escaping (_ json:AnyObject?, _ response:URLResponse?, _ error:NSError?, _ responseCode:Int)->Void){
        jsonBaseRequest(urlString: urlString, dataBody: nil, requestMethod: "GET", success: success, failure: failure)
    }
    
    static func jsonPost(urlString:String, databody:AnyObject?, success:@escaping (_ json:AnyObject, _ response:URLResponse?, _ error:NSError?)->Void, failure:@escaping (_ json:AnyObject?, _ response:URLResponse?, _ error:NSError?, _ responseCode:Int)->Void){
        jsonBaseRequest(urlString: urlString, dataBody: databody, requestMethod: "POST", success: success, failure: failure)
    }
    
    static func jsonDelete(urlString:String, success:@escaping (_ json:AnyObject, _ response:URLResponse?, _ error:NSError?)->Void, failure:@escaping (_ json:AnyObject?, _ response:URLResponse?, _ error:NSError?, _ responseCode:Int)->Void){
        jsonBaseRequest(urlString: urlString, dataBody: nil, requestMethod: "DELETE", success: success, failure: failure)
    }
    
    //download
    
    static func download(){
        
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
}
