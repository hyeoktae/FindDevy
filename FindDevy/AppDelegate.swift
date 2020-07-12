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
  var lastLocation: [Double]? {
    get {
      autoreleasepool {
        UserDefaults.standard.object(forKey: "loc") as? [Double]
      }
    }
    set {
      autoreleasepool {
        UserDefaults.standard.set(newValue, forKey: "loc")
      }
    }
  }
  var myKey: String? {
    get {
      autoreleasepool {
        UserDefaults.standard.string(forKey: "key")
      }
    }
    set {
      autoreleasepool {
        UserDefaults.standard.set(newValue, forKey: "key")
      }
    }
  }
  
  func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()
    guard myKey == nil else { return true }
    myKey = UUID.init().uuidString
    return true
  }
  
  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    // Override point for customization after application launch.
    ref = Database.database().reference()
    
    let eFormatter = DateFormatter()
    eFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    self.ref?.child(self.myKey ?? "err").child("optionDid").child(eFormatter.string(from: Date())).setValue(launchOptions)
    
    locaManager = CLLocationManager()
    
    checkAuthorizationStatus()
    
    return true
  }
  
  func applicationDidBecomeActive(_ application: UIApplication) {
    self.ref?.child(self.myKey ?? "err").child("terminated").setValue(false)
  }
  
  func applicationWillTerminate(_ application: UIApplication) {
    self.ref?.child(self.myKey ?? "err").child("terminated").setValue(true)
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
    locaManager?.delegate = self
    locaManager?.pausesLocationUpdatesAutomatically = true
    locaManager?.desiredAccuracy = kCLLocationAccuracyHundredMeters // 정확도
    locaManager?.allowsBackgroundLocationUpdates = true
    locaManager?.distanceFilter = 100 // x 미터마다 체크 5미터 마다 위치 업데이트
    locaManager?.activityType = .other
    locaManager?.startUpdatingLocation()
    locaManager?.startMonitoringSignificantLocationChanges()
    
  }
  
}

extension AppDelegate: CLLocationManagerDelegate {
  func locationManagerDidPauseLocationUpdates(_ manager: CLLocationManager) {
    let eFormatter = DateFormatter()
    eFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    self.ref?.child(self.myKey ?? "err").child("paused").child(eFormatter.string(from: Date())).setValue(true)
    guard let center = manager.location?.coordinate else { return }
    let region = CLCircularRegion(center: center, radius: 300.0, identifier: "lastLoc")
    region.notifyOnExit = true
    region.notifyOnEntry = false
    let trigger = UNLocationNotificationTrigger(region: region, repeats: false)
    
    let content = UNMutableNotificationContent()
    content.title = "움직였네?"
    content.body = "이거 눌러라"
    content.sound = UNNotificationSound.default
    
    let request = UNNotificationRequest(identifier: "lastLoc", content: content, trigger: trigger)
    
    let noti = UNUserNotificationCenter.current()
    noti.add(request, withCompletionHandler: { (error) in
         if let error = error {
              self.ref?.child(self.myKey ?? "err").child("notiError").setValue(error)
         } else {
          self.ref?.child(self.myKey ?? "err").child("notiSuccess").setValue(request)
         }
    })
    
  }
  
  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    
    guard let temp = locations.first else { return }
    let dist = CLLocation(latitude: lastLocation?[0] ?? 0, longitude: lastLocation?[1] ?? 0).distance(from: temp)
    let eFormatter = DateFormatter()
    eFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    self.ref?.child(self.myKey ?? "err").child("paused").child(eFormatter.string(from: Date())).setValue(false)
    self.ref?.child(self.myKey ?? "err").child("dist").child(eFormatter.string(from: temp.timestamp)).setValue(dist)
    
    guard lastLocation != nil else {
      self.lastLocation = [temp.coordinate.latitude, temp.coordinate.longitude]
      saveLocationToServer(temp)
      return }
    guard CLLocation(latitude: lastLocation?[0] ?? 0, longitude: lastLocation?[1] ?? 0).distance(from: temp).magnitude > 100.0 else {
      self.lastLocation = [temp.coordinate.latitude, temp.coordinate.longitude]
      return }
    saveLocationToServer(temp)
  }
  
  private func saveLocationToServer(_ temp: CLLocation) {
    let dayFormatter = DateFormatter()
    dayFormatter.dateFormat = "yyyyMMdd"
    let hourFormatter = DateFormatter()
    hourFormatter.dateFormat = "HHmmss"
    let currentDay = dayFormatter.string(from: temp.timestamp)
    let currentHour = hourFormatter.string(from: temp.timestamp)
    
    let param = [
      "lat": temp.coordinate.latitude,
      "lng": temp.coordinate.longitude,
      "altitude": temp.altitude,
      "speed": temp.speed,
      "course": temp.course,
      "accuracy": temp.horizontalAccuracy
    ]
    
    self.ref?.child(self.myKey ?? "err").child("loc").child(currentDay).child(currentHour).setValue(param)
  }
}

