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
    label.text = "나는 비데~\n비 데 비비비 데!!!\n위치 전송중..."
    label.numberOfLines = 0
    return label
  }()
  
  var copyBtn: UIButton = {
    let btn = UIButton()
    btn.setTitle("나의 키 복사", for: .normal)
    btn.setTitleColor(.black, for: .normal)
    return btn
  }()
  
  override func didMoveToSuperview() {
    super.didMoveToSuperview()
    self.backgroundColor = .white
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    [title, copyBtn].forEach{self.addSubview($0)}
    
    title.snp.makeConstraints {
      $0.center.equalToSuperview()
    }
    
    copyBtn.snp.makeConstraints {
      $0.centerX.equalToSuperview()
      $0.bottom.equalToSuperview().offset(-100)
    }
  }
  
}
