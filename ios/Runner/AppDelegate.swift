import UIKit
import Flutter
import AVFoundation

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    private var objectDetector: ObjectDetector?
    private let detectorChannelName = "com.example.object_detector/detector"
    private let permissionsChannelName = "com.example.object_detector/permissions"
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
        
        // Set up detector channel
        let detectorChannel = FlutterMethodChannel(name: detectorChannelName, binaryMessenger: controller.binaryMessenger)
        objectDetector = ObjectDetector()
        
        detectorChannel.setMethodCallHandler({ [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            guard let self = self else { return }
            
            switch call.method {
            case "detectObjects":
                guard let arguments = call.arguments as? [String: Any],
                      let imageBytes = arguments["imageBytes"] as? FlutterStandardTypedData,
                      let width = arguments["width"] as? Int,
                      let height = arguments["height"] as? Int else {
                    result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing or invalid arguments", details: nil))
                    return
                }
                
                DispatchQueue.global(qos: .userInitiated).async {
                    let detections = self.objectDetector?.detectObjects(imageData: imageBytes.data, width: width, height: height) ?? []
                    
                    DispatchQueue.main.async {
                        result(detections)
                    }
                }
                
            case "dispose":
                self.objectDetector?.close()
                self.objectDetector = nil
                result(nil)
                
            default:
                result(FlutterMethodNotImplemented)
            }
        })
        
        // Set up permissions channel
        let permissionsChannel = FlutterMethodChannel(name: permissionsChannelName, binaryMessenger: controller.binaryMessenger)
        
        permissionsChannel.setMethodCallHandler({ (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            switch call.method {
            case "requestCameraPermission":
                self.requestCameraPermission(result: result)
                
            default:
                result(FlutterMethodNotImplemented)
            }
        })
        
        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    private func requestCameraPermission(result: @escaping FlutterResult) {
        let authStatus = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch authStatus {
        case .authorized:
            result(true)
            
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    result(granted)
                }
            }
            
        case .denied, .restricted:
            result(false)
            
        @unknown default:
            result(false)
        }
    }
    
    override func applicationWillTerminate(_ application: UIApplication) {
        objectDetector?.close()
        objectDetector = nil
        super.applicationWillTerminate(application)
    }
}