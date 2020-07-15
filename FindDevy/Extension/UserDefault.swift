//
//  UserDefault.swift
//  FindDevy
//
//  Created by hyeoktae kwon on 2020/07/12.
//  Copyright © 2020 hyeoktae kwon. All rights reserved.
//

import Foundation

extension UserDefaults {
  static var otherKey: String? {
    get {
      autoreleasepool {
        self.standard.string(forKey: "otherKey")
      }
    }
    set {
      autoreleasepool {
        self.standard.setValue(newValue, forKey: "otherKey")
      }
    }
  }
  
  static var lastLocation: [Double]? {
    get {
      autoreleasepool {
        self.standard.object(forKey: "loc") as? [Double]
      }
    }
    set {
      autoreleasepool {
        self.standard.set(newValue, forKey: "loc")
      }
    }
  }
  
  static var myKey: String? {
    get {
      autoreleasepool {
        self.standard.string(forKey: "key")
      }
    }
    set {
      autoreleasepool {
        self.standard.set(newValue, forKey: "key")
      }
    }
  }
  
  static var roll: String? {
    get {
      autoreleasepool {
        self.standard.string(forKey: "roll")
      }
    }
    set {
      autoreleasepool {
        self.standard.set(newValue, forKey: "roll")
      }
    }
  }
  
}
