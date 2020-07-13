//
//  SelectRollView.swift
//  FindDevy
//
//  Created by hyeoktae kwon on 2020/07/13.
//  Copyright © 2020 hyeoktae kwon. All rights reserved.
//

import UIKit
import SnapKit

class SelectRollView: UIView {
  let yesBtn: UIButton = {
    let btn = UIButton()
    btn.setTitle("네", for: .normal)
    btn.setTitleColor(.black, for: .normal)
    btn.tag = 1
    return btn
  }()
  
  let noBtn: UIButton = {
    let btn = UIButton()
    btn.setTitle("아니용", for: .normal)
    btn.setTitleColor(.black, for: .normal)
    btn.tag = 2
    return btn
  }()
  
  let title: UILabel = {
    let label = UILabel()
    label.text = "나는 비이데에~"
    label.textColor = .black
    return label
  }()
  
  override func didMoveToSuperview() {
    super.didMoveToSuperview()
    self.backgroundColor = .white
  }
  
  override func layoutSubviews() {
    super.layoutSubviews()
    addSubviews()
    setupSNP()
  }
  
  private func addSubviews() {
    [yesBtn, noBtn, title].forEach {
      self.addSubview($0)
    }
  }
  
  private func setupSNP() {
    title.snp.makeConstraints {
      $0.centerX.equalToSuperview()
      $0.top.equalToSuperview().offset(100)
    }
    
    yesBtn.snp.makeConstraints {
      $0.centerX.equalToSuperview().multipliedBy(0.75)
      $0.bottom.equalToSuperview().offset(-100)
    }
    
    noBtn.snp.makeConstraints {
      $0.centerX.equalToSuperview().multipliedBy(1.25)
      $0.bottom.equalToSuperview().offset(-100)
    }
  }

}
