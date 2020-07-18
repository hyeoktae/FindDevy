//
//  AppDelegate.swift
//  FindDevy
//
//  Created by hyeoktae kwon on 2020/07/11.
//  Copyright © 2020 hyeoktae kwon. All rights reserved.
//

import UIKit
import Firebase
import OneSignal
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
  
  lazy var notificationReceivedBlock: OSHandleNotificationReceivedBlock = { notification in
    print("Received Notification - \(notification?.payload.notificationID) - \(notification?.payload.title)")
    DispatchQueue.global(qos: .background).async {
      let state = CLLocationManager.authorizationStatus()
      if state == .authorizedAlways || state == .authorizedWhenInUse {
        self.locaManager?.desiredAccuracy = kCLLocationAccuracyBestForNavigation // 정확도
        self.locaManager?.distanceFilter = 1 // x 미터마다 체크 5미터 마다 위치 업데이트
//        self.startUpdatingLocation()
        notification?.payload.threadId
      }
    }
  }
  
  lazy var notificationOpenedBlock: OSHandleNotificationActionBlock = { result in
    // This block gets called when the user reacts to a notification received
    let payload: OSNotificationPayload = result!.notification.payload
    
    var fullMessage = payload.body
    print("Message = \(fullMessage)")
    if payload.contentAvailable {
      DispatchQueue.global(qos: .background).async {
        let state = CLLocationManager.authorizationStatus()
        if state == .authorizedAlways || state == .authorizedWhenInUse {
          self.locaManager?.desiredAccuracy = kCLLocationAccuracyBestForNavigation // 정확도
          self.locaManager?.distanceFilter = 1 // x 미터마다 체크 5미터 마다 위치 업데이트
//          self.startUpdatingLocation()
        }
      }
    }
//    if payload.additionalData != nil {
//      if payload.title != nil {
//        let messageTitle = payload.title
//        print("Message Title = \(messageTitle!)")
//      }
//
//      let additionalData = payload.additionalData
//      if additionalData?["actionSelected"] != nil {
//        fullMessage = fullMessage! + "\nPressed ButtonID: \(additionalData!["actionSelected"])"
//      }
//    }
  }
  
  var delegate: LocalDelegate?
  var locaManager: CLLocationManager?
  var ref: DatabaseReference?
  var fs: Firestore?
  var task : UIBackgroundTaskIdentifier = UIBackgroundTaskIdentifier.invalid
  
  func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()
    guard UserDefaults.myKey == nil else { return true }
    UserDefaults.myKey = UUID.init().uuidString
    return true
  }
  
  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    ref = Database.database().reference()
    fs = Firestore.firestore()
    
    setupWindow()
    
    OneSignal.setLogLevel(.LL_VERBOSE, visualLevel: .LL_NONE)
    let onesignalInitSettings = [kOSSettingsKeyAutoPrompt: false, kOSSettingsKeyInAppLaunchURL: false]
    
    OneSignal.initWithLaunchOptions(launchOptions,
    appId: "f150dfd8-b292-4948-9963-cc27fd189121",
    handleNotificationReceived: notificationReceivedBlock,
    handleNotificationAction: notificationOpenedBlock,
    settings: onesignalInitSettings)
    
    OneSignal.inFocusDisplayType = OSNotificationDisplayType.notification;
    
    OneSignal.promptForPushNotifications(userResponse: { _ in })
    OneSignal.register { (_) in }
    
    return true
  }
  
  func setupWindow() {
    window = UIWindow()
    let vc = UserDefaults.roll == nil ? SelectRollVC() : (UserDefaults.roll == "devy" ? ChildVC() : FinderVC())
    window?.rootViewController = vc
    window?.makeKeyAndVisible()
    CLLocationManager.authorizationStatus()
    if UserDefaults.roll == "devy" {
      locaManager = CLLocationManager()
      checkAuthorizationStatus()
    }
    OneSignal.promptForPushNotifications(userResponse: { accepted in
      print("User accepted notifications: \(accepted)")
      if accepted {
        DispatchQueue.global().async {
          self.fs?.collection("OneToken").document(UserDefaults.myKey ?? "err").setData(["token": OneSignal.getUserDevice().getUserId() ?? "err"])
        }
      }
    })
  }
  
  func applicationDidBecomeActive(_ application: UIApplication) {
    delegate?.viewDidBecomeActive()
    self.ref?.child(UserDefaults.myKey ?? "err").child("terminated").setValue(false, withCompletionBlock: { (err, _) in
      self.ref?.child(UserDefaults.myKey ?? "err").child("terminated").removeAllObservers()
    })
  }
  
  func applicationDidEnterBackground(_ application: UIApplication) {
    delegate?.viewDidEnterBackground()
  }
  
  func applicationWillTerminate(_ application: UIApplication) {
    self.ref?.child(UserDefaults.myKey ?? "err").child("terminated").setValue(true, withCompletionBlock: { (err, _) in
      self.ref?.child(UserDefaults.myKey ?? "err").child("terminated").removeAllObservers()
    })
    
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
    locaManager?.pausesLocationUpdatesAutomatically = false
    locaManager?.desiredAccuracy = kCLLocationAccuracyNearestTenMeters // 정확도
    locaManager?.allowsBackgroundLocationUpdates = true
    locaManager?.distanceFilter = 500 // x 미터마다 체크 5미터 마다 위치 업데이트
    locaManager?.activityType = .other
    locaManager?.startUpdatingLocation()
    locaManager?.startMonitoringSignificantLocationChanges()
    
  }
  
}

extension AppDelegate: CLLocationManagerDelegate {
//  func locationManagerDidPauseLocationUpdates(_ manager: CLLocationManager) {
//    self.ref?.child(UserDefaults.myKey ?? "err").child("paused").setValue(true, withCompletionBlock: { (err, _) in
//      self.ref?.child(UserDefaults.myKey ?? "err").child("paused").removeAllObservers()
//    })
//
//    guard let center = manager.location?.coordinate else { return }
//    let region = CLCircularRegion(center: center, radius: 300.0, identifier: "lastLoc")
//    region.notifyOnExit = true
//    region.notifyOnEntry = false
//    let trigger = UNLocationNotificationTrigger(region: region, repeats: false)
//
//    let content = UNMutableNotificationContent()
//    content.title = "움직였네?"
//    content.body = "이거 눌러라"
//    content.sound = UNNotificationSound.default
//
//    let request = UNNotificationRequest(identifier: "lastLoc", content: content, trigger: trigger)
//
//    let noti = UNUserNotificationCenter.current()
//    noti.add(request, withCompletionHandler: { (_) in
////         if let error = error {
////              self.ref?.child(UserDefaults.myKey ?? "err").child("notiError").setValue(error)
////         } else {
////          self.ref?.child(UserDefaults.myKey ?? "err").child("notiSuccess").setValue(request)
////         }
//    })
//
//  }
  
  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    
    guard let temp = locations.last else { return }
//    self.ref?.child(UserDefaults.myKey ?? "err").child("paused").setValue(false, withCompletionBlock: { (err, _) in
//      self.ref?.child(UserDefaults.myKey ?? "err").child("paused").removeAllObservers()
//    })
    
    saveLocationToServer(temp)
    
    locaManager?.desiredAccuracy = kCLLocationAccuracyNearestTenMeters // 정확도
    locaManager?.distanceFilter = 500 // x 미터마다 체크 5미터 마다 위치 업데이트
  }
  
  private func saveLocationToServer(_ temp: CLLocation) {
    let currentDate = temp.timestamp.toYear()
    guard currentDate == Date().toYear() else { return }
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
    
    self.ref?.child(UserDefaults.myKey ?? "err").child("currentLoc").setValue(param, withCompletionBlock: { (err, _) in
      self.ref?.child(UserDefaults.myKey ?? "err").child("currentLoc").removeAllObservers()
    })
    
    param.updateValue(temp.timestamp, forKey: "date")
    self.fs?.collection("Location").document(UserDefaults.myKey ?? "err").collection(currentDate).document(currentHour).setData(param, completion: { (_) in
//      UIApplication.shared.endBackgroundTask(<#T##identifier: UIBackgroundTaskIdentifier##UIBackgroundTaskIdentifier#>)
      
    })
  }
}

