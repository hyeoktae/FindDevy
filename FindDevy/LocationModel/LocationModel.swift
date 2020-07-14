//
//  LocationModel.swift
//  FindDevy
//
//  Created by hyeoktae kwon on 2020/07/15.
//  Copyright © 2020 hyeoktae kwon. All rights reserved.
//

import Foundation
import FirebaseFirestore

struct LocData {
  var coor: (Double, Double) = (0, 0)
  var accuracy: Int = 0
  var at: String = ""
  var altitude: Int = 0
  var course: Int = 0
  var speed: Int = 0
  var date: Date?
  var isEnable: Bool { coor != (0, 0) }
  
  init(data: [String: Any]) {
    self.coor = ((data["lat"] as? Double) ?? 0, (data["lng"] as? Double) ?? 0)
    self.accuracy = (data["accuracy"] as? Int) ?? 0
    self.at = (data["at"] as? String) ?? ""
    self.altitude = (data["altitude"] as? Int) ?? 0
    self.course = (data["course"] as? Int) ?? 0
    self.speed = (data["speed"] as? Int) ?? 0
    self.date = (data["date"] as? Timestamp)?.dateValue()
  }
}
