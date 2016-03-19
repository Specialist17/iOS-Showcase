//
//  DataService.swift
//  iOS-showcase
//
//  Created by Fernando on 3/19/16.
//  Copyright © 2016 Specialist. All rights reserved.
//

import Foundation
import Firebase

class DataService {
    
    class var DS: DataService{
        get{
            struct Service{
                static let ds = DataService()
            }
            return Service.ds
        }
    }
    
    private var _REF_BASE = Firebase(url: "https://ioscourse-showcase.firebaseio.com")
    
    var REF_BASE: Firebase{
        return _REF_BASE
    }
    
}