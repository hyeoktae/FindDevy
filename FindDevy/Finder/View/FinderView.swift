//
//  FinderView.swift
//  FindDevy
//
//  Created by hyeoktae kwon on 2020/07/13.
//  Copyright © 2020 hyeoktae kwon. All rights reserved.
//

import UIKit
import MapKit
import SnapKit

class FinderView: UIView {
  let dateTextField: UITextField = {
    let tf = UITextField()
    tf.placeholder = "yyyyMMdd"
    return tf
  }()
  
  let searchBtn: UIButton = {
    let btn = UIButton()
    btn.setTitle("검색", for: .normal)
    btn.setTitleColor(.black, for: .normal)
    return btn
  }()
  
  let mapView: MKMapView = {
    let map = MKMapView()
    return map
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
    [dateTextField, searchBtn, mapView].forEach {
      self.addSubview($0)
    }
  }
  
  private func setupSNP() {
    dateTextField.snp.makeConstraints {
      $0.top.equalTo(self.snp.topMargin)
      $0.leading.equalToSuperview()
      $0.height.equalTo(50)
    }
    
    searchBtn.snp.makeConstraints {
      $0.leading.equalTo(dateTextField.snp.trailing).offset(5)
      $0.top.equalTo(self.snp.topMargin)
      $0.trailing.equalToSuperview()
      $0.width.height.equalTo(50)
    }
    
    mapView.snp.makeConstraints {
      $0.top.equalTo(searchBtn.snp.bottom).offset(5)
      $0.leading.trailing.bottom.equalToSuperview()
    }
    
  }
  
}
