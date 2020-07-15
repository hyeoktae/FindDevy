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
  func changeTodayValue(loc: LocData, terminated: Bool, paused: Bool)
}

class DB {
  var ref: DatabaseReference?
  let fs = Firestore.firestore()
  var delegate: DBDelegate?
  
  init() {
    self.ref = Database.database().reference()
    UserDefaults.otherKey = "3492414B-B182-4F9F-A77A-4C2568763D5F"
  }
  
  func getTodayLocations() {
    guard let key = UserDefaults.otherKey else { return }
    ref?.child(key).observe(.value, with: {
      guard let value = $0.value as? [String: Any] else { return }
      guard let terminated = value["terminated"] as? Bool, let paused = value["paused"] as? Bool, let loc = value["currentLoc"] as? [String: Any] else { return }
      self.delegate?.changeTodayValue(loc: LocData(data: loc), terminated: terminated, paused: paused)
    })
  }
  
  func getTargetLocation(date: String, completion: @escaping ([LocData]) -> ()) {
    guard let key = UserDefaults.otherKey else { return }
    fs.collection("Location").document(key).collection(date).getDocuments { (snap, err) in
      guard err == nil else {
        completion([])
        return }
      guard let snap = snap else {
        completion([])
        return }
      let temp = snap.documents.compactMap{LocData(data: $0.data())}.sorted{$0.date ?? Date() < $1.date ?? Date()}
      completion(temp)
    }
  }
  
  func removeObserver() {
    guard let key = UserDefaults.otherKey else { return }
    ref?.child(key).removeAllObservers()
  }
  
  
}
