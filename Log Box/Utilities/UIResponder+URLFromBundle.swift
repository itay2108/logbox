//
//  UIResponder+URLFromBundle.swift
//  Log Box
//
//  Created by itay gervash on 24/05/2020.
//  Copyright © 2020 itay gervash. All rights reserved.
//

import UIKit

extension UIResponder {
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    func remove(file atURL: URL?) {
        guard atURL != nil else { return }
        
        do {
            try FileManager.default.removeItem(at: atURL!)
        } catch {
           print("error removing recording from file directory: \(error)")
        }

    }
    
}
