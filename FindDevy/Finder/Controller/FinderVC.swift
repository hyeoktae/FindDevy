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
import OneSignal

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
    finderView.locRequestBtn.addTarget(self, action: #selector(didTapLocRequestBtn(_:)), for: .touchUpInside)
    db.delegate = self
    AppDelegate.instance.delegate = self
    self.finderView.mapView.delegate = self
    
    
    getTargetLoc(date: Date().toYear()) {
      self.db.getTodayLocations()
    }
    
    self.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap(_:))))
  }
  
  @objc func handleTap(_ sender: UITapGestureRecognizer) {
    if sender.state == .ended {
      self.view.endEditing(true)
    }
    sender.cancelsTouchesInView = false
  }
  
  private func getTargetLoc(date: String, completion: @escaping () -> ()) {
    self.removeOverlays()
    db.getTargetLocation(date: date) {
      switch $0 {
      case .success(let loc):
        guard loc.count != 0 else {
          Isaac.toast("\(date)에 새로운 위치가 없어요!", view: self.view)
          return }
        
        let locs = loc.enumerated().map{ (i, l) -> MKPointAnnotation in
          let anno = MKPointAnnotation()
          anno.coordinate = CLLocationCoordinate2D(latitude: l.coor.0, longitude: l.coor.1)
          anno.title = "\(i + 1)"
          return anno
        }
        
        if let last = locs.last {
          self.setRegion(point: last.coordinate)
        }
        
        self.model.annotations = locs
        
        self.setOverlays(annotations: locs)
        
        completion()
      case .failure(let err):
        switch err {
        case .networkErr:
          Isaac.toast("네트워크 에러 발생!!!", view: self.view)
        case .noData:
          Isaac.toast("\(date)에 새로운 위치가 없어요!", view: self.view)
        case .noKey:
          Isaac.toast("등록된 토큰이 없어요!", view: self.view)
        }
        completion()
      }
      
      
    }
  }
  
  private func removeOverlays() {
    self.finderView.mapView.removeAnnotations(self.model.annotations)
    self.finderView.mapView.removeOverlays(self.model.lineArr)
    self.model.lineArr = []
    self.model.annotations = []
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
        getTargetLoc(date: Date().toYear()) {
          self.db.getTodayLocations()
        }
        Isaac.toast("코드 등록 완료!", view: self.view)
        return
      }
    }
    guard let now = self.finderView.dateTextField.text, now.isValidateDate() else {
      Isaac.toast("날짜를 확인해주세요!", view: self.view)
      return }
    guard now.isLessThanToday() else {
      Isaac.toast("미래는 알 수 없어요!", view: self.view)
      return }
    now == Date().toYear() ? getTargetLoc(date: now) { self.db.getTodayLocations() } : getTargetLoc(date: now){}
  }
  
  @objc private func didTapLocRequestBtn(_ sender: UIButton) {
    let alertController = UIAlertController(title: "위치 갱신이 안되나요?", message: "그러면 메세지와 함께 위치를 요청해서, 앱을 키도록 해야해요!\n조용히 전달 누르면 푸시가 없어요!", preferredStyle: .alert)
    
    alertController.addTextField { (tf) in
      tf.placeholder = "제목"
    }
    
    alertController.addTextField { (tf) in
      tf.placeholder = "내용"
    }
    
    let withMessageBtn = UIAlertAction(title: "메세지와 함께 전달", style: .default, handler: { (action) in
      let title = alertController.textFields?.first?.text ?? "앱이 죽었다!!!"
      let content = alertController.textFields?.last?.text ?? "이거 눌러서 살려주세요!!!"
      self.setParam(true, content: (title, content))
    })
    
    alertController.addAction(withMessageBtn)

    alertController.addAction(UIAlertAction(title: "조용히 전달", style: .default, handler: { (action) in
      self.setParam(false)
    }))
    
    alertController.addAction(UIAlertAction(title: "안해유", style: .cancel, handler: { _ in }))

    self.present(alertController, animated: true, completion: nil)
    
    
    
  }
  
  private func setParam(_ message: Bool, content: (String, String) = ("", "")) {
    
    getOtherToken {
      guard let token = $0 else {
        Isaac.toast("등록된 토큰이 없어요!", view: self.view)
        return }
      var param: [String : Any] = ["include_player_ids": [token], "content_available": true, "priority": 10]
      //      OneSignal.postNotification(["contents": ["en": "Test Message"], "include_player_ids": ["3009e210-3166-11e5-bc1b-db44eb02b120"]])
      if !message {
        self.sendPush(param)
      } else {
        param.updateValue(["ko": content.1], forKey: "contents")
        param.updateValue(["ko": content.0], forKey: "headings")
        self.sendPush(param)
      }
      
    }
  }
  
  private func sendPush(_ param: [String: Any]) {
    OneSignal.postNotification(param, onSuccess: { (info) in
      //          print("success!!!: ", info)
      // recipients
      Isaac.toast("요청 성공!!!", view: self.view)
    }) {
      Isaac.toast($0?.localizedDescription ?? "요청 실패!!!", view: self.view)
    }
  }
  
  @objc private func showPushNotiBtn(_ sender: UIButton) {
    
  }
  
  private func getOtherToken(completion: @escaping (String?) -> ()) {
    db.getOtherOneToken(completion: completion)
  }
  
}

extension FinderVC: LocalDelegate {
  func viewDidEnterBackground() {
    self.removeOverlays()
    db.removeObserver()
  }
  
  func viewDidBecomeActive() {
    guard let now = self.finderView.dateTextField.text, now.isValidateDate() else {
      getTargetLoc(date: Date().toYear()) {
        self.db.getTodayLocations()
      }
      return }
    now == Date().toYear() ? getTargetLoc(date: now) { self.db.getTodayLocations() } : getTargetLoc(date: now){}
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
      self.finderView.mapView.selectAnnotation(lastAnnotaion, animated: true)
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
