//
//  FinderModel.swift
//  FindDevy
//
//  Created by hyeoktae kwon on 2020/07/14.
//  Copyright © 2020 hyeoktae kwon. All rights reserved.
//

import Foundation
import MapKit

struct FinderModel {
  var todayData: [String: [String: Any]] = [:]
  var annotations: [MKPointAnnotation] = []
}
