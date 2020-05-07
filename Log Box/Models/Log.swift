//
//  Log.swift
//  Log Box
//
//  Created by itay gervash on 07/04/2020.
//  Copyright © 2020 itay gervash. All rights reserved.
//

import Foundation
import RealmSwift

class Log: Object {
    
    @objc dynamic var date = Date()
    @objc dynamic var name = ""
    @objc dynamic var transcript: String?
    @objc dynamic var recording = Data()
    @objc dynamic var isDefaultName = true
    
    
}
