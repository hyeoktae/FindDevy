//
//  StringExtension.swift
//  FindDevy
//
//  Created by hyeoktae kwon on 2020/07/15.
//  Copyright © 2020 hyeoktae kwon. All rights reserved.
//

import Foundation

extension Date {
  func toYear() -> String {
    let dayFormatter = DateFormatter()
    dayFormatter.dateFormat = "yyyyMMdd"
    dayFormatter.locale = Locale(identifier: "ko")
    return dayFormatter.string(from: self)
  }
  
  func toHour() -> String {
    let hourFormatter = DateFormatter()
    hourFormatter.dateFormat = "HHmmss"
    hourFormatter.locale = Locale(identifier: "ko")
    return hourFormatter.string(from: self)
  }
  
  
}
