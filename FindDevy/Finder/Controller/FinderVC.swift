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
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.view.addSubview(finderView)
    finderView.snp.makeConstraints {
      $0.top.leading.trailing.bottom.equalToSuperview()
    }
    
    finderView.dateTextField.text = Date().toYear()
    finderView.searchBtn.addTarget(self, action: #selector(didTapSearchBtn(_:)), for: .touchUpInside)
    db.delegate = self
    AppDelegate.instance.delegate = self
    self.finderView.mapView.delegate = self
    
    db.getTodayLocations()
    getTargetLoc(date: Date().toYear())
    
    self.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap(_:))))
  }
  
  @objc func handleTap(_ sender: UITapGestureRecognizer) {
    if sender.state == .ended {
      self.view.endEditing(true)
    }
    sender.cancelsTouchesInView = false
  }
  
  private func getTargetLoc(date: String) {
    self.removeOverlays()
    db.getTargetLocation(date: date) {
      guard $0.count != 0 else { return }
      
      var locs = $0.enumerated().map{ (i, l) -> MKPointAnnotation in
        let anno = MKPointAnnotation()
        anno.coordinate = CLLocationCoordinate2D(latitude: l.coor.0, longitude: l.coor.1)
        anno.title = "\(i + 1)"
        return anno
      }
      
      let last = locs.removeLast()
      self.setRegion(point: last.coordinate)
      
      self.model.annotations = locs
      
      self.setOverlays(annotations: locs)
    }
  }
  
  private func removeOverlays() {
    self.finderView.mapView.removeOverlays(self.model.lineArr)
    self.finderView.mapView.removeAnnotations(self.model.annotations)
    self.model.annotations = []
    self.model.lineArr = []
  }
  
  private func setRegion(point: CLLocationCoordinate2D) {
    let span = MKCoordinateSpan(latitudeDelta: 0.003, longitudeDelta: 0.003)
    let currentRegion = MKCoordinateRegion(center: point, span: span)
    self.finderView.mapView.setRegion(currentRegion, animated: true)
  }
  
  private func setOverlays(annotations: [MKPointAnnotation]) {
    DispatchQueue.main.async {
      self.finderView.mapView.addAnnotations(annotations)
      let points = annotations.map{$0.coordinate}
      let line = MKPolyline(coordinates: points, count: points.count)
      self.model.lineArr.append(line)
      self.finderView.mapView.addOverlay(line)
    }
  }
  
  @objc private func didTapSearchBtn(_ sender: UIButton) {
    if let tempCode = self.finderView.dateTextField.text {
      if tempCode.count > 20 {
        UserDefaults.otherKey = tempCode
        self.finderView.dateTextField.text = Date().toYear()
        db.getTodayLocations()
        getTargetLoc(date: Date().toYear())
        Isaac.toast("코드 등록 완료!")
        return
      }
    }
    guard let now = self.finderView.dateTextField.text, now.isValidateDate() else {
      Isaac.toast("날짜를 확인해주세요!")
      return }
    now == Date().toYear() ? db.getTodayLocations() : ()
    getTargetLoc(date: now)
  }
  
}

extension FinderVC: LocalDelegate {
  func viewDidEnterBackground() {
    db.removeObserver()
    self.removeOverlays()
  }
  
  func viewDidBecomeActive() {
    guard let now = self.finderView.dateTextField.text, now.isValidateDate() else {
      db.getTodayLocations()
      getTargetLoc(date: Date().toYear())
      return }
    now == Date().toYear() ? db.getTodayLocations() : ()
    getTargetLoc(date: now)
  }
  
}

extension FinderVC: DBDelegate {
  func changeTodayValue(loc: LocData, terminated: Bool, paused: Bool) {
    guard loc.isEnable else { return }
    
    let state = self.model.currentAnnotation.coordinate.latitude != CLLocationCoordinate2D().latitude
    
    let currentPoint = CLLocationCoordinate2D(latitude: loc.coor.0, longitude: loc.coor.1)
    let lastPoint = self.model.currentAnnotation.coordinate
    let points: [CLLocationCoordinate2D] = [lastPoint, currentPoint]
    let line = MKPolyline(coordinates: points, count: points.count)
    
    
    let beforeAnnotation = MKPointAnnotation()
    beforeAnnotation.title = "\(self.model.annotations.count + 1)"
    beforeAnnotation.coordinate = lastPoint
    
    let lastAnnotaion = MKPointAnnotation()
    lastAnnotaion.title = loc.at
    lastAnnotaion.coordinate = currentPoint
    DispatchQueue.main.async {
      if state {
        self.model.lineArr.append(line)
        self.finderView.mapView.addOverlay(line)
        self.finderView.mapView.removeAnnotation(self.model.currentAnnotation)
        self.finderView.mapView.addAnnotation(beforeAnnotation)
      }
      self.finderView.mapView.addAnnotation(lastAnnotaion)
      self.model.currentAnnotation = lastAnnotaion
    }
    
  }
  
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
