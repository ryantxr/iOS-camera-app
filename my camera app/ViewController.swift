//
//  ViewController.swift
//  my camera app
//
//  Created by ryan teixeira on 2/25/16.
//  Copyright © 2016 Ryan Teixeira. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    @IBOutlet var videoView: UIView!
    @IBOutlet var noCameraLabel: UILabel!
    
    let captureSession = AVCaptureSession()
    var captureDevice : AVCaptureDevice?
    var previewLayer : AVCaptureVideoPreviewLayer?
    var hasCameraPermission: Bool = false
    var checkingCameraPermission: Bool = false
    var askedForPermission: Bool = false
    var captureDeviceCount = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        noCameraLabel.hidden = true
        hasCameraPermission = getCameraPermission() == .Authorized
        captureSession.sessionPreset = AVCaptureSessionPresetHigh
        checkVideoDevices()
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        hasCameraPermission = getCameraPermission() == .Authorized
    }
    
    override func viewDidAppear(animated: Bool) {
        if captureDeviceCount == 0 {
            print("No cameras on this device")
            alert("This device has no cameras", title: "We need a camera")
        }
        else if captureDevice == nil {
            if !hasCameraPermission && !checkingCameraPermission  {
                print("Needs camera permission")
                let message = "Please go to settings and allow the app to access the camera."
                let alertTitle = "We need a camera"
                let alert = UIAlertController(title: alertTitle, message: message, preferredStyle: UIAlertControllerStyle.Alert)
                dispatch_async(dispatch_get_main_queue()) {
                    alert.addAction(UIAlertAction(title: "Close", style: UIAlertActionStyle.Default) {
                        (action: UIAlertAction) in
                        // do action for Close
                        })
                    alert.addAction(UIAlertAction(title: "Settings", style: UIAlertActionStyle.Default) {
                        (action: UIAlertAction) in
                        // do action for Settings
                        dispatch_async( dispatch_get_main_queue() ) {
                                UIApplication.sharedApplication().openAppSettings()
                        }
                    })
                    self.presentViewController(alert, animated: true, completion: nil)
                }
            }
            else {
                print("No camera found")
                alert("This device does not have a camera", title: "We need a camera")
            }
        }
    }
    
    
    // Check if there are any camera devices and check permissions
    func checkVideoDevices() {
        let devices = AVCaptureDevice.devices()
        print("Cameras & Microphones")
        print(devices)
        captureDeviceCount = 0
        // Check for permission and request it if needed
        hasCameraPermission = getCameraPermission() == .Authorized
        
/*        if hasCameraPermission { */
            for device in devices {
                // Make sure this particular device supports video
                if (device.hasMediaType(AVMediaTypeVideo)) {
                    captureDeviceCount++
                    // Finally check the position and confirm we've got the back camera
                    if(device.position == AVCaptureDevicePosition.Back) {
                        captureDevice = device as? AVCaptureDevice
                        noCameraLabel.hidden = true
                    }
                }
            }
            if captureDevice != nil {
                self.beginSession()
            }
            else {
                // No capture device found
                noCameraLabel.hidden = false
                videoView.hidden = true
            }
        /*}
        else {
            // we don't have permission to the camera
            noCameraLabel.hidden = false
            videoView.hidden = true
        }*/
    }
    
    // start the camera session
    func beginSession(){
        configureDevice()
        
        do {
            if let device = captureDevice {
                let avCaptureDeviceInput = try AVCaptureDeviceInput(device: device)
                captureSession.addInput(avCaptureDeviceInput)
                addOutputForBarcodeMetadata()
                
                self.previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
                if self.previewLayer == nil {
                    return
                }
                self.previewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
                previewLayer?.frame = self.videoView.bounds
                
                self.videoView.layer.addSublayer(previewLayer!)
                captureSession.startRunning()
            }
        }
        catch let error as NSError {
            print(error.description)
        }
    }

    // Check the camera permission and ask for it if needed.
    func getCameraPermission() -> AVAuthorizationStatus {
        let authStatus: AVAuthorizationStatus  = AVCaptureDevice.authorizationStatusForMediaType(AVMediaTypeVideo)
        switch(authStatus) {
        case .Authorized:
            print("Camera allowed")
            hasCameraPermission = true
        case .Denied:
            print("Camera denied")
            hasCameraPermission = false
            // Give option to go to settings
        case .Restricted:
            print("Camera restricted")
            // Don't know what to do with this
        case .NotDetermined:
            print("Camera not determined")
            // Need to ask for permission
            let mediaType = AVMediaTypeVideo
            checkingCameraPermission = true
            dispatch_async(dispatch_get_main_queue()) {
                AVCaptureDevice.requestAccessForMediaType(mediaType) {
                    (granted) in
                    self.checkingCameraPermission = false
                    if granted == true {
                        print("Granted access to \(mediaType)" )
                        self.hasCameraPermission = true
                    } else {
                        print("Not granted access to \(mediaType)")
                        self.hasCameraPermission = false
                    }
                }
            }
            
        }
        askedForPermission = true
        return authStatus
    }

    // Ask the user for permission to the camera
    func askForCameraPermission(completionHandler: (granted: Bool)->Void) {
        let mediaType = AVMediaTypeVideo
        AVCaptureDevice.requestAccessForMediaType(mediaType) {
            (granted) in
            if granted == true {
                print("Granted access to \(mediaType)" )
            } else {
                print("Not granted access to \(mediaType)")
            }
            completionHandler(granted: granted)
        }
    }
    
    let screenWidth = UIScreen.mainScreen().bounds.size.width
    // begin touches
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        print("touchesBegan fired")
        if let anyTouch = touches.first {
            let touchPercent = anyTouch.locationInView(self.view).x / screenWidth
            focusTo(Float(touchPercent))
        }
    }
    //
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        print("touchesMoved fired")
        if let anyTouch = touches.first {
            let touchPercent = anyTouch.locationInView(self.view).x / screenWidth
            focusTo(Float(touchPercent))
        }
    }
    
    // Set some configuration options
    func configureDevice() {
        if let device = captureDevice {
            do {
                try device.lockForConfiguration()
                device.focusMode = .AutoFocus
                device.unlockForConfiguration()
            }
            catch let error as NSError {
                error.description
            }
        }
    }
    
    // Capture metadata for barcodes
    var metadataOutput = AVCaptureMetadataOutput()
    func addOutputForBarcodeMetadata() {
        
        metadataOutput.setMetadataObjectsDelegate(self, queue: dispatch_get_main_queue())
        
        captureSession.addOutput(metadataOutput)
        
        // This line is required, as little sense at that makes
        metadataOutput.metadataObjectTypes = metadataOutput.availableMetadataObjectTypes
    }
    
    func focusTo(value : Float) {
        if let device = captureDevice {
            do{
                try device.lockForConfiguration()
                device.setFocusModeLockedWithLensPosition(value, completionHandler: {
                    (time) -> Void in
                    //
                })
                device.unlockForConfiguration()
            }
            catch let error as NSError {
                print(error.description)
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

