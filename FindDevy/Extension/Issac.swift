//
//  Issac.swift
//  FindDevy
//
//  Created by hyeoktae kwon on 2020/07/15.
//  Copyright © 2020 hyeoktae kwon. All rights reserved.
//

import UIKit
import ToastSwiftFramework

final class Isaac {
  static let shared = Isaac()
  
  private init() {
    ToastManager.shared.position = .bottom
    
  }
  
  static var windows: UIView? {
    UIApplication.shared.windows.last
  }
  
  class func toast(_ text: String, view: UIView? = nil) {
    guard view == nil else {
      view?.makeToast(" " + text + " ", duration: 2.0, position: .bottom)
      windows?.makeToast(" " + text + " ", duration: 2.0, position: .bottom)
      return }
    guard let view = windows else { return }
    view.makeToast(" " + text + " ", duration: 2.0, position: .bottom)
  }
}
