//
//  SelectRollVC.swift
//  FindDevy
//
//  Created by hyeoktae kwon on 2020/07/13.
//  Copyright © 2020 hyeoktae kwon. All rights reserved.
//

import UIKit
import SnapKit

class SelectRollVC: UIViewController {
  
  let selectRollView = SelectRollView()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.view.addSubview(selectRollView)
    selectRollView.snp.makeConstraints {
      $0.top.leading.bottom.trailing.equalToSuperview()
    }
    selectRollView.yesBtn.addTarget(self, action: #selector(didTapBtns(_:)), for: .touchUpInside)
    selectRollView.noBtn.addTarget(self, action: #selector(didTapBtns(_:)), for: .touchUpInside)
  }
  
  @objc private func didTapBtns(_ sender: UIButton) {
    switch sender.tag {
    case 1:
      UserDefaults.standard.setValue("devy", forKey: "roll")
    case 2:
      UserDefaults.standard.setValue("tass", forKey: "roll")
    default:
      break
    }
    self.dismiss(animated: true) {
      AppDelegate.instance.setupWindow()
    }
  }
  
}
