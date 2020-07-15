//
//  StringExtension.swift
//  FindDevy
//
//  Created by hyeoktae kwon on 2020/07/15.
//  Copyright © 2020 hyeoktae kwon. All rights reserved.
//

import Foundation

let localeID = Locale.preferredLanguages.first ?? "ko_KR"

extension Date {
  func toYear() -> String {
    let dayFormatter = DateFormatter()
    dayFormatter.dateFormat = "yyyyMMdd"
    dayFormatter.locale = Locale(identifier: localeID)
    return dayFormatter.string(from: self)
  }
  
  func toHour() -> String {
    let hourFormatter = DateFormatter()
    hourFormatter.dateFormat = "HHmmss"
    hourFormatter.locale = Locale(identifier: localeID)
    return hourFormatter.string(from: self)
  }
  
  
}
