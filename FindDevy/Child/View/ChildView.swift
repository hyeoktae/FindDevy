//
//  ChildView.swift
//  FindDevy
//
//  Created by hyeoktae kwon on 2020/07/13.
//  Copyright © 2020 hyeoktae kwon. All rights reserved.
//

import UIKit
import SnapKit

class ChildView: UIView {

  let title: UILabel = {
    let label = UILabel()
    label.text = "나는 비데~\n위치 전송중..."
    label.numberOfLines = 2
    return label
  }()
  
  override func didMoveToSuperview() {
    super.didMoveToSuperview()
    self.backgroundColor = .white
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    self.addSubview(title)
    title.snp.makeConstraints {
      $0.center.equalToSuperview()
    }
  }
  
}
