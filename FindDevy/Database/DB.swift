//
//  Database.swift
//  FindDevy
//
//  Created by hyeoktae kwon on 2020/07/13.
//  Copyright © 2020 hyeoktae kwon. All rights reserved.
//

import Foundation
import Firebase

protocol DBDelegate: class {
  func changeTodayValue(value: [String : [String : Any]])
}

class DB {
  var ref: DatabaseReference?
  var delegate: DBDelegate?
  
  init() {
    self.ref = Database.database().reference()
  }
  
  func getTodayLocations() {
    //    ref?.child("9135269C-0D50-41BA-828A-972ECEBE1A49").child("loc").observe(.childAdded, with: {
    let dayFormatter = DateFormatter()
    dayFormatter.dateFormat = "yyyyMMdd"
    dayFormatter.locale = Locale(identifier: "ko")
    let today = dayFormatter.string(from: Date())
    ref?.child("9135269C-0D50-41BA-828A-972ECEBE1A49").child("loc").child(today).observe(.childAdded, with: {
      guard let loc = $0.value as? [String: Any] else { return }
      self.delegate?.changeTodayValue(value: [$0.key : loc])
    })
  }
  
  func getTargetLocation(date: String, completion: @escaping ([String : [String : Any]]) -> ()) {
    ref?.child("9135269C-0D50-41BA-828A-972ECEBE1A49").child("loc").child(date).observeSingleEvent(of: .value, with: {
      if $0.exists() {
        guard let value = $0.value as? [String : [String : Any]] else {
          completion([:])
          return }
        completion(value)
      } else {
        completion([:])
      }
    })
  }
  
  func removeObserver() {
    let dayFormatter = DateFormatter()
    dayFormatter.dateFormat = "yyyyMMdd"
    dayFormatter.locale = Locale(identifier: "ko")
    let today = dayFormatter.string(from: Date())
    ref?.child("9135269C-0D50-41BA-828A-972ECEBE1A49").child("loc").child(today).removeAllObservers()
  }
  
  
}
