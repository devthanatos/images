//
//  CameraViewController.swift
//  images
//
//  Created by Michael Akopyants on 11/12/2016.
//  Copyright © 2016 devthanatos. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

protocol CameraControllerDelegate {
    
    func didTakeImage(image: UIImage)
    
}
class CameraViewController: UIViewController
{
    @IBOutlet weak var previewView: PreviewView!
    var delegate: CameraControllerDelegate?
    
    private let session = AVCaptureSession()
    @IBAction func snapshotAction(_ sender: Any) {
        if (photoOutput.connection(withMediaType: AVMediaTypeVideo)) != nil {
            photoOutput.capturePhoto(with: AVCapturePhotoSettings(), delegate: self)
        }
    }
    @IBOutlet weak var snapshotButton: UIButton!
    
    private var isSessionRunning = false
    
    private let sessionQueue = DispatchQueue(label: "camera session queue", attributes: [], target: nil)
    
    private var setupResult: SessionSetupResult = .success
    
    var videoDeviceInput: AVCaptureDeviceInput!
    
    private let photoOutput = AVCapturePhotoOutput()

    private var sessionRunningObserveContext = 0
    
    private enum SessionSetupResult
    {
        case success
        case notAuthorized
        case configurationFailed
    }
    
    override var prefersStatusBarHidden: Bool
    {
        return true
    }
    
    override func viewDidLoad()
    {
        self.view.backgroundColor = UIColor.black
        previewView.backgroundColor = UIColor.black
        super.viewDidLoad()
        snapshotButton.setTitle("", for: .normal)
        
        snapshotButton.backgroundColor = UIColor.clear
        snapshotButton.layer.borderWidth = 4
        snapshotButton.layer.borderColor = UIColor.white.cgColor
        snapshotButton.layer.cornerRadius = self.snapshotButton.frame.width/2.0
        snapshotButton.isEnabled = false
        previewView.session = session
        previewView.videoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        
        switch AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo)
        {
        case .authorized:
            break
        case .notDetermined:
            
            sessionQueue.suspend()
            AVCaptureDevice.requestAccess(forMediaType: AVMediaTypeVideo, completionHandler:
                {
                    [unowned self] granted in
                    if !granted
                    {
                        self.setupResult = .notAuthorized
                    }
                    self.sessionQueue.resume()
                })
        default:
            
            setupResult = .notAuthorized
        }
        
        sessionQueue.async { [unowned self] in
            self.configureSession()
        }
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillDisappear(_ animated: Bool)
    {
        sessionQueue.async { [unowned self] in
            if self.setupResult == .success
            {
                self.session.stopRunning()
                self.isSessionRunning = self.session.isRunning
                self.removeObservers()
            }
        }
        
        super.viewWillDisappear(animated)
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        
        sessionQueue.async {
            switch self.setupResult {
            case .success:
                // Only setup observers and start the session running if setup succeeded.
                self.addObservers()
                self.session.startRunning()
                self.isSessionRunning = self.session.isRunning
                
            case .notAuthorized:
                DispatchQueue.main.async { [unowned self] in
                    let message = NSLocalizedString("AVCam doesn't have permission to use the camera, please change privacy settings", comment: "Alert message when the user has denied access to the camera")
                    let alertController = UIAlertController(title: "AVCam", message: message, preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Alert OK button"), style: .cancel, handler: nil))
                    alertController.addAction(UIAlertAction(title: NSLocalizedString("Settings", comment: "Alert button to open Settings"), style: .`default`, handler: { action in
                        UIApplication.shared.open(URL(string: UIApplicationOpenSettingsURLString)!, options: [:], completionHandler: nil)
                    }))
                    
                    self.present(alertController, animated: true, completion: nil)
                }
                
            case .configurationFailed:
                DispatchQueue.main.async { [unowned self] in
                    let message = NSLocalizedString("Unable to capture media", comment: "Alert message when something goes wrong during capture session configuration")
                    let alertController = UIAlertController(title: "AVCam", message: message, preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Alert OK button"), style: .cancel, handler: nil))
                    
                    self.present(alertController, animated: true, completion: nil)
                }
            }
        }
    }

    
    private func configureSession()
    {
        
        if setupResult != .success
        {
            return
        }
        
        session.beginConfiguration()
        
        session.sessionPreset = AVCaptureSessionPresetPhoto
        do
        {
            var defaultVideoDevice: AVCaptureDevice?
            
            if let dualCameraDevice = AVCaptureDevice.defaultDevice(withDeviceType: .builtInDuoCamera, mediaType: AVMediaTypeVideo, position: .back)
            {
                defaultVideoDevice = dualCameraDevice
            }
            else if let backCameraDevice = AVCaptureDevice.defaultDevice(withDeviceType: .builtInWideAngleCamera, mediaType: AVMediaTypeVideo, position: .back)
            {
            
                defaultVideoDevice = backCameraDevice
            }
            
            let videoDeviceInput = try AVCaptureDeviceInput(device: defaultVideoDevice)
            if session.canAddInput(videoDeviceInput)
            {
                session.addInput(videoDeviceInput)
                self.videoDeviceInput = videoDeviceInput
                
                DispatchQueue.main.async
                    {
                        self.previewView.videoPreviewLayer.connection.videoOrientation = .portrait
                    }
            }
            else
            {
                print("Could not add video device input to the session")
                setupResult = .configurationFailed
                session.commitConfiguration()
                return
            }
        }
        catch
        {
            print("Could not create video device input: \(error)")
            setupResult = .configurationFailed
            session.commitConfiguration()
            return
        }
        if session.canAddOutput(photoOutput)
        {
            session.addOutput(photoOutput)
            
            photoOutput.isHighResolutionCaptureEnabled = true
            
        }
        else {
            print("Could not add photo output to the session")
            setupResult = .configurationFailed
            session.commitConfiguration()
            return
        }
        
        session.commitConfiguration()
    }
    
    private func focus(with focusMode: AVCaptureFocusMode, exposureMode: AVCaptureExposureMode, at devicePoint: CGPoint, monitorSubjectAreaChange: Bool)
    {
        sessionQueue.async { [unowned self] in
            if let device = self.videoDeviceInput.device
            {
                do
                {
                    try device.lockForConfiguration()
                    
                    if device.isFocusPointOfInterestSupported && device.isFocusModeSupported(focusMode) {
                        device.focusPointOfInterest = devicePoint
                        device.focusMode = focusMode
                    }
                    
                    if device.isExposurePointOfInterestSupported && device.isExposureModeSupported(exposureMode)
                    {
                        device.exposurePointOfInterest = devicePoint
                        device.exposureMode = exposureMode
                    }
                    
                    device.isSubjectAreaChangeMonitoringEnabled = monitorSubjectAreaChange
                    device.unlockForConfiguration()
                }
                catch
                {
                    print("Could not lock device for configuration: \(error)")
                }
            }
        }
    }
    //MARK! Observers
    private func addObservers()
    {
        session.addObserver(self, forKeyPath: "running", options: .new, context: &sessionRunningObserveContext)
        
        NotificationCenter.default.addObserver(self, selector: #selector(subjectAreaDidChange), name: Notification.Name("AVCaptureDeviceSubjectAreaDidChangeNotification"), object: videoDeviceInput.device)
        NotificationCenter.default.addObserver(self, selector: #selector(sessionRuntimeError), name: Notification.Name("AVCaptureSessionRuntimeErrorNotification"), object: session)
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(sessionInterruptionEnded), name: Notification.Name("AVCaptureSessionInterruptionEndedNotification"), object: session)
    }
    
    private func removeObservers()
    {
        NotificationCenter.default.removeObserver(self)
        
        session.removeObserver(self, forKeyPath: "running", context: &sessionRunningObserveContext)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?)
    {
        if context == &sessionRunningObserveContext
        {
            let newValue = change?[.newKey] as AnyObject?
            guard let isSessionRunning = newValue?.boolValue else { return }
            DispatchQueue.main.async { [unowned self] in
                
                self.snapshotButton.isEnabled = isSessionRunning
            }
        }
        else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
    func subjectAreaDidChange(notification: NSNotification)
    {
        let devicePoint = CGPoint(x: 0.5, y: 0.5)
        focus(with: .autoFocus, exposureMode: .continuousAutoExposure, at: devicePoint, monitorSubjectAreaChange: false)
    }
    
    func sessionRuntimeError(notification: NSNotification)
    {
        guard let errorValue = notification.userInfo?[AVCaptureSessionErrorKey] as? NSError else {
            return
        }
        
        let error = AVError(_nsError: errorValue)
        print("Capture session runtime error: \(error)")

        if error.code == .mediaServicesWereReset
        {
            sessionQueue.async { [unowned self] in
                if self.isSessionRunning
                {
                    self.session.startRunning()
                    self.isSessionRunning = self.session.isRunning
                }
                else
                {
                    DispatchQueue.main.async { [unowned self] in
                        self.snapshotButton.isEnabled = false
                    }
                }
            }
        }
    }
    
    
    func sessionInterruptionEnded(notification: NSNotification)
    {
        print("Capture session interruption ended")        
        self.session.startRunning()
        self.snapshotButton.isEnabled = true
    }
}

extension CameraViewController : AVCapturePhotoCaptureDelegate {
    func capture(_ captureOutput: AVCapturePhotoOutput, didFinishProcessingPhotoSampleBuffer photoSampleBuffer: CMSampleBuffer?, previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: Error?) {
        let imageData = AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: photoSampleBuffer!, previewPhotoSampleBuffer: previewPhotoSampleBuffer)
        let image = UIImage(data: imageData!)
        
        delegate?.didTakeImage(image: image!)
        self.dismiss(animated: true, completion: nil)
    }

}
