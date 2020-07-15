//
//  StringExtension.swift
//  FindDevy
//
//  Created by hyeoktae kwon on 2020/07/15.
//  Copyright © 2020 hyeoktae kwon. All rights reserved.
//

import Foundation

extension String {
  func toYear() -> Date? {
    let dayFormatter = DateFormatter()
    dayFormatter.dateFormat = "yyyyMMdd"
    dayFormatter.locale = Locale(identifier: localeID)
    return dayFormatter.date(from: self)
  }
  
  func toHour() -> Date? {
    let hourFormatter = DateFormatter()
    hourFormatter.dateFormat = "HHmmss"
    hourFormatter.locale = Locale(identifier: localeID)
    return hourFormatter.date(from: self)
  }
  
  func isValidateDate() -> Bool {
    let dayFormatter = DateFormatter()
    dayFormatter.dateFormat = "yyyyMMdd"
    return dayFormatter.date(from: self) != nil
  }
  
}
