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
    self.finderView.mapView.delegate = self
    
    db.getTodayLocations()
    db.getTargetLocation(date: "20200715") {
      var locs = $0.enumerated().map{ (i, l) -> MKPointAnnotation in
        let anno = MKPointAnnotation()
        anno.coordinate = CLLocationCoordinate2D(latitude: l.coor.0, longitude: l.coor.1)
        if i == 0 {
          anno.title = "s"
        }
        return anno
      }
      
      let last = locs.removeLast()
      let span = MKCoordinateSpan(latitudeDelta: 0.003, longitudeDelta: 0.003)
      let currentRegion = MKCoordinateRegion(center: last.coordinate, span: span)
      self.finderView.mapView.setRegion(currentRegion, animated: true)
      
      self.model.annotations = locs
      DispatchQueue.main.async {
        self.finderView.mapView.addAnnotations(locs)
        let points = locs.map{$0.coordinate}
        let line = MKPolyline(coordinates: points, count: points.count)
        self.finderView.mapView.addOverlay(line)
      }
      
    }
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
  func changeTodayValue(loc: LocData, terminated: Bool, paused: Bool) {
    guard loc.isEnable else { return }
    let annotaion = MKPointAnnotation()
    annotaion.title = loc.at
    annotaion.coordinate = CLLocationCoordinate2D(latitude: loc.coor.0, longitude: loc.coor.1)
    DispatchQueue.main.async {
      self.finderView.mapView.removeAnnotation(self.model.currentAnnotation)
      self.finderView.mapView.addAnnotation(annotaion)
      self.model.currentAnnotation = annotaion
    }
    
  }
  
//  func changeTodayValue(value: [String : [String : Any]]) {
//    value.forEach { (key, value) in
//      self.model.todayData.updateValue(value, forKey: key)
//    }
//
//    let temp = self.model.todayData.values.compactMap { value -> MKPointAnnotation? in
//      if let lat = value["lat"] as? Double, let lng = value["lng"] as? Double {
//        let annotaion = MKPointAnnotation()
//        annotaion.coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lng)
//        return annotaion
//      } else {
//        return nil
//      }
//    }
//
//    self.model.annotations.append(contentsOf: temp)
//
//    if finderView.dateTextField.text == today {
//      self.finderView.mapView.addAnnotations(self.model.annotations)
//      print(self.model.annotations.count)
////      let annotation: MKPointAnnotation = {
////        let a = MKPointAnnotation()
////        a.title = "\(mapView.annotations.count+1)번째 행선지"
////        a.subtitle = "\(mapView.annotations.count+1)"
////        a.coordinate = center
////        return a
////      }()
//    }
//
//  }
  
  
}

extension FinderVC: MKMapViewDelegate {
  func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
    if let line = overlay as? MKPolyline {
      let renderer = MKPolylineRenderer(polyline: line)
      renderer.strokeColor = .red
      renderer.lineWidth = 0.5
      return renderer
    } else {
      return MKOverlayRenderer()
    }
  }
}
