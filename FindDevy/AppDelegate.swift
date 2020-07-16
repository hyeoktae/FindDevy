//
//  AppDelegate.swift
//  FindDevy
//
//  Created by hyeoktae kwon on 2020/07/11.
//  Copyright © 2020 hyeoktae kwon. All rights reserved.
//

import UIKit
import Firebase
import FirebaseMessaging
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
  var task : UIBackgroundTaskIdentifier = UIBackgroundTaskIdentifier.invalid
  
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
    
    Messaging.messaging().delegate = self
    UNUserNotificationCenter.current().delegate = self
    let authOptions: UNAuthorizationOptions = [.alert, .sound]
    UNUserNotificationCenter.current().requestAuthorization(
      options: authOptions,
      completionHandler: {_, _ in })
    
    application.registerForRemoteNotifications()
    
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
  
  func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    let deviceTokenString = deviceToken.reduce("", {$0 + String(format: "%02X", $1)})
    print("[Log] deviceToken :", deviceTokenString)
    Messaging.messaging().apnsToken = deviceToken
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
    locaManager?.distanceFilter = 500 // x 미터마다 체크 5미터 마다 위치 업데이트
    locaManager?.activityType = .other
    locaManager?.startUpdatingLocation()
    locaManager?.startMonitoringSignificantLocationChanges()
    
  }
  
}

extension AppDelegate: UNUserNotificationCenterDelegate, MessagingDelegate {
  func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
    let dataDict: [String: String] = ["token": fcmToken]
    NotificationCenter.default.post(name: Notification.Name("FCMToken"), object: nil, userInfo: dataDict)
    self.fs?.collection("fcmToken").document(UserDefaults.myKey ?? "err").setData(dataDict)
    
  }
  
  func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
    
    
    registerBackgroundTask {
      completionHandler(.newData)
    }
    
//    if let userInfo = userInfo as? [String: AnyObject] {
//        let parseNotificationOperation = ParseNotificationOperation(userInfo: userInfo, fetchCompletionHandler: completionHandler)
//        MainService.shared.enqueueApnsOperation(parseNotificationOperation)
//
//        if (tsk == UIBackgroundTaskInvalid) {
//            task = UIApplication.sharedApplication().beginBackgroundTaskWithExpirationHandler { () -> Void in
//                self.endTask()
//            }
//        }
//    }
    
  }
  
  func registerBackgroundTask(completion: @escaping () -> ()) {
    task = UIApplication.shared.beginBackgroundTask {
      
      UIApplication.shared.endBackgroundTask(self.task)
      self.task = .invalid
      
      DispatchQueue.global(qos: .background).async {
        print("background fetch")
        self.locaManager?.desiredAccuracy = kCLLocationAccuracyBestForNavigation // 정확도
        self.locaManager?.distanceFilter = 1 // x 미터마다 체크 5미터 마다 위치 업데이트
        let state = CLLocationManager.authorizationStatus()
        if state == .authorizedAlways || state == .authorizedWhenInUse {
          self.startUpdatingLocation()
        }
        Firestore.firestore().collection("temp").document(UserDefaults.myKey ?? "err").setData(["temp": "in background"], completion: { (_) in
          if self.task != .invalid {
            UIApplication.shared.endBackgroundTask(self.task)
            self.task = .invalid
          }
          completion()
        })
      }
    }
  }
  
  func endBackgroundTask() {
    print("Background task ended.")
    UIApplication.shared.endBackgroundTask(self.task)
    self.task = .invalid
    
  }

  
  func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    print("willPresent")
    completionHandler([[.alert, .sound]])
  }
  
  func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
    print("didReceive")
    locaManager?.desiredAccuracy = kCLLocationAccuracyBestForNavigation // 정확도
    locaManager?.distanceFilter = 1 // x 미터마다 체크 5미터 마다 위치 업데이트
   let state = CLLocationManager.authorizationStatus()
   if state == .authorizedAlways || state == .authorizedWhenInUse {
     self.startUpdatingLocation()
   }
    completionHandler()
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
    
//    guard UserDefaults.lastLocation != nil else {
//      UserDefaults.lastLocation = [temp.coordinate.latitude, temp.coordinate.longitude]
//      saveLocationToServer(temp)
//      return }
//    guard CLLocation(latitude: UserDefaults.lastLocation?[0] ?? 0, longitude: UserDefaults.lastLocation?[1] ?? 0).distance(from: temp).magnitude > 500.0 else {
//      UserDefaults.lastLocation = [temp.coordinate.latitude, temp.coordinate.longitude]
  //      return }
    saveLocationToServer(temp)
    
    manager.desiredAccuracy = kCLLocationAccuracyHundredMeters // 정확도
    manager.distanceFilter = 500 // x 미터마다 체크 5미터 마다 위치 업데이트
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
    
    self.ref?.child(UserDefaults.myKey ?? "err").child("currentLoc").setValue(param)
    
    param.updateValue(temp.timestamp, forKey: "date")
    self.fs?.collection("Location").document(UserDefaults.myKey ?? "err").collection(currentDate).document(currentHour).setData(param)
  }
}

