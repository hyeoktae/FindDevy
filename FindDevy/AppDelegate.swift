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

protocol LocalDelegate: class {
  func viewDidEnterBackground()
  func viewDidBecomeActive()
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
  
  var window: UIWindow?
  
  static var instance: AppDelegate {
    return (UIApplication.shared.delegate as! AppDelegate)
  }
  
  var delegate: LocalDelegate?
  var locaManager: CLLocationManager?
  var ref: DatabaseReference?
  var fs: Firestore?
  
  func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()
    CLLocationManager.authorizationStatus()
    guard UserDefaults.myKey == nil else { return true }
    UserDefaults.myKey = UUID.init().uuidString
    return true
  }
  
  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    
    ref = Database.database().reference()
    fs = Firestore.firestore()
    
    setupWindow()
    
    if UserDefaults.roll == "devy" {
      locaManager = CLLocationManager()
      checkAuthorizationStatus()
    }
    
    return true
  }
  
  func setupWindow() {
    window = UIWindow()
    let vc = UserDefaults.roll == nil ? SelectRollVC() : (UserDefaults.roll == "devy" ? ChildVC() : FinderVC())
    window?.rootViewController = vc
    window?.makeKeyAndVisible()
  }
  
  func applicationDidBecomeActive(_ application: UIApplication) {
    self.ref?.child(UserDefaults.myKey ?? "err").child("terminated").setValue(false)
    delegate?.viewDidBecomeActive()
  }
  
  func applicationDidEnterBackground(_ application: UIApplication) {
    delegate?.viewDidEnterBackground()
  }
  
  func applicationWillTerminate(_ application: UIApplication) {
    self.ref?.child(UserDefaults.myKey ?? "err").child("terminated").setValue(true)
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
    locaManager?.desiredAccuracy = kCLLocationAccuracyNearestTenMeters // 정확도
    locaManager?.allowsBackgroundLocationUpdates = true
    locaManager?.distanceFilter = 500 // x 미터마다 체크 5미터 마다 위치 업데이트
    locaManager?.activityType = .other
    locaManager?.startUpdatingLocation()
    locaManager?.startMonitoringSignificantLocationChanges()
    
  }
  
}

extension AppDelegate: CLLocationManagerDelegate {
  func locationManagerDidPauseLocationUpdates(_ manager: CLLocationManager) {
    self.ref?.child(UserDefaults.myKey ?? "err").child("paused").setValue(true)
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
              self.ref?.child(UserDefaults.myKey ?? "err").child("notiError").setValue(error)
         } else {
          self.ref?.child(UserDefaults.myKey ?? "err").child("notiSuccess").setValue(request)
         }
    })
    
  }
  
  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    
    guard let temp = locations.first else { return }
    self.ref?.child(UserDefaults.myKey ?? "err").child("paused").setValue(false)
    
    guard UserDefaults.lastLocation != nil else {
      UserDefaults.lastLocation = [temp.coordinate.latitude, temp.coordinate.longitude]
      saveLocationToServer(temp)
      return }
    guard CLLocation(latitude: UserDefaults.lastLocation?[0] ?? 0, longitude: UserDefaults.lastLocation?[1] ?? 0).distance(from: temp).magnitude > 500.0 else {
      UserDefaults.lastLocation = [temp.coordinate.latitude, temp.coordinate.longitude]
      return }
    saveLocationToServer(temp)
  }
  
  private func saveLocationToServer(_ temp: CLLocation) {
    let currentHour = temp.timestamp.toHour()
    var param = [
      "at": currentHour,
      "lat": temp.coordinate.latitude,
      "lng": temp.coordinate.longitude,
      "altitude": Int(temp.altitude),
      "speed": Int(temp.speed),
      "course": Int(temp.course),
      "accuracy": Int(temp.horizontalAccuracy)
      ] as [String : Any]
    
    self.ref?.child(UserDefaults.myKey ?? "err").child("currentLoc").setValue(param)
    
    param.updateValue(temp.timestamp, forKey: "date")
    self.fs?.collection("Location").document(UserDefaults.myKey ?? "err").collection(temp.timestamp.toYear()).document(currentHour).setData(param)
  }
}

