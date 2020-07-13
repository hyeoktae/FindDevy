//
//  FinderVC.swift
//  FindDevy
//
//  Created by hyeoktae kwon on 2020/07/13.
//  Copyright © 2020 hyeoktae kwon. All rights reserved.
//

import UIKit
import SnapKit
import MapKit

class FinderVC: UIViewController {
  
  var model = FinderModel()
  let finderView = FinderView()
  let db = DB()
  var today: String {
    let dayFormatter = DateFormatter()
    dayFormatter.dateFormat = "yyyyMMdd"
    dayFormatter.locale = Locale(identifier: "ko")
    return dayFormatter.string(from: Date())
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.view.addSubview(finderView)
    finderView.snp.makeConstraints {
      $0.top.leading.trailing.bottom.equalToSuperview()
    }
    
    finderView.dateTextField.text = today
    db.delegate = self
    AppDelegate.instance.delegate = self
    
    db.getTodayLocations()
  }
}

extension FinderVC: LocalDelegate {
  func viewDidEnterBackground() {
    db.removeObserver()
    self.finderView.mapView.removeAnnotations(self.model.annotations)
    self.model.annotations = []
  }
  
  func viewDidBecomeActive() {
    db.getTodayLocations()
  }
  
  
}

extension FinderVC: DBDelegate {
  func changeTodayValue(value: [String : [String : Any]]) {
    value.forEach { (key, value) in
      self.model.todayData.updateValue(value, forKey: key)
    }
    
    let temp = self.model.todayData.values.compactMap { value -> MKPointAnnotation? in
      if let lat = value["lat"] as? Double, let lng = value["lng"] as? Double {
        let annotaion = MKPointAnnotation()
        annotaion.coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lng)
        return annotaion
      } else {
        return nil
      }
    }
    
    self.model.annotations.append(contentsOf: temp)
    
    if finderView.dateTextField.text == today {
      self.finderView.mapView.addAnnotations(self.model.annotations)
      print(self.model.annotations.count)
//      let annotation: MKPointAnnotation = {
//        let a = MKPointAnnotation()
//        a.title = "\(mapView.annotations.count+1)번째 행선지"
//        a.subtitle = "\(mapView.annotations.count+1)"
//        a.coordinate = center
//        return a
//      }()
    }
    
  }
  
  
}
