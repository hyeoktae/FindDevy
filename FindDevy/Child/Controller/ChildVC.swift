//
//  ChildVC.swift
//  FindDevy
//
//  Created by hyeoktae kwon on 2020/07/13.
//  Copyright © 2020 hyeoktae kwon. All rights reserved.
//

import UIKit
import SnapKit

class ChildVC: UIViewController {
  
  let childView = ChildView()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.view.addSubview(childView)
    childView.snp.makeConstraints {
      $0.leading.top.bottom.trailing.equalToSuperview()
    }
    
  }
}
