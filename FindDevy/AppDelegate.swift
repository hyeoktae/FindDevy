//
//  AppDelegate.swift
//  FindDevy
//
//  Created by hyeoktae kwon on 2020/07/11.
//  Copyright © 2020 hyeoktae kwon. All rights reserved.
//

import UIKit
import Firebase
import CoreLocation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
  
  static var instance: AppDelegate {
    return (UIApplication.shared.delegate as! AppDelegate)
  }
  
  var locaManager: CLLocationManager?
  var ref: DatabaseReference?
  var lastLocation: CLLocation?
  
  func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()
    locaManager = CLLocationManager()
    locaManager?.delegate = self
    checkAuthorizationStatus()
    return true
  }
  
  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    // Override point for customization after application launch.
    ref = Database.database().reference()
    
    
    
    
    return true
  }
  
  
}

extension AppDelegate {
  // 어느 시점에서 위치권한이 있는지
  @discardableResult
  func checkAuthorizationStatus() -> Bool {
    switch CLLocationManager.authorizationStatus() {
    case .notDetermined: // 사용자가 위치권한 서비스를 사용할 수 있는 여부를 선택하지 않았을때
      // 앱이 foreground에 있는동안 위치권한 서비스를 요청한다.위치권한 달라고 요청\
      fallthrough
    case .restricted, .denied:
      // Disable location features // 앱은 위치 서비스를 사용할 권한이 없다. 사용자가 설정에서 전체적으로 사용 중지
      // 위치 권한 alert을 띄운다
      
      locaManager?.requestAlwaysAuthorization()
      return false
    case .authorizedWhenInUse: // 앱을 사용하는 동안 위치서비스를 시작하도록 앱을 승인함 위치 업데이트를 한다.
      //앱을 키는 순간 위치 업데이트를 계속한다. 앱을 끌때까지
      fallthrough
    case .authorizedAlways:   // 언제든지 사용가능
      startUpdatingLocation()
      return true
    @unknown default:
      locaManager?.requestAlwaysAuthorization()
      return false
    }
  }
  
  func startUpdatingLocation() {
    let status = CLLocationManager.authorizationStatus()
    guard status == .authorizedAlways || status == .authorizedWhenInUse, CLLocationManager.locationServicesEnabled() else { return }
    
    locaManager?.desiredAccuracy = kCLLocationAccuracyNearestTenMeters // 정확도
    locaManager?.allowsBackgroundLocationUpdates = true
    locaManager?.distanceFilter = 30 // x 미터마다 체크 5미터 마다 위치 업데이트
    locaManager?.activityType = .other
    locaManager?.startMonitoringSignificantLocationChanges()
  }
  
}

extension AppDelegate: CLLocationManagerDelegate {
  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    
    guard let temp = locations.first else { return }
    print(1)
    guard lastLocation != nil else {
      self.lastLocation = temp
      saveLocationToServer(temp)
      print(2)
      return }
    guard lastLocation?.distance(from: temp).magnitude ?? 0 > 20.0 else {
      self.lastLocation = temp
      print(3)
      return }
    print(4)
    saveLocationToServer(temp)
  }
  
  private func saveLocationToServer(_ temp: CLLocation) {
    print(5)
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyyMMddHHmmss"
    let currentTime = dateFormatter.string(from: temp.timestamp)
    
    let param = [
      "lat": temp.coordinate.latitude,
      "lng": temp.coordinate.longitude,
      "altitude": temp.altitude,
      "speed": temp.speed,
      "course": temp.course,
      "accuracy": temp.horizontalAccuracy
    ]
    
    self.ref?.child("devy").child(currentTime).setValue(param)
  }
}

