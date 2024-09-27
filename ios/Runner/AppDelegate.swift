import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

      let controller = self.window.rootViewController as! FlutterViewController
      let channel = FlutterMethodChannel.init(name: "cross", binaryMessenger: controller as! FlutterBinaryMessenger)

      channel.setMethodCallHandler { (call, result) in
          Thread {
              if call.method == "root" {

                  let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]

                  result(documentsPath)

              }
              else if call.method == "saveImageToGallery"{
                  if let args = call.arguments as? String{

                      do {
                          let fileURL: URL = URL(fileURLWithPath: args)
                              let imageData = try Data(contentsOf: fileURL)

                          if let uiImage = UIImage(data: imageData) {
                              UIImageWriteToSavedPhotosAlbum(uiImage, nil, nil, nil)
                              result("OK")
                          }else{
                              result(FlutterError(code: "", message: "Error loading image ", details: ""))
                          }

                      } catch {
                              result(FlutterError(code: "", message: "Error loading image : \(error)", details: ""))
                      }

                  }else{
                      result(FlutterError(code: "", message: "params error", details: ""))
                  }
              }
              else{
                  result(FlutterMethodNotImplemented)
              }
          }.start()
      }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
