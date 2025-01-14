//
//  CameraManager.swift
//  camera
//
//  Created by Natalia Terlecka on 10/10/14.
//  Copyright (c) 2014 Imaginary Cloud. All rights reserved.
//

import UIKit
import AVFoundation
import Photos
import PhotosUI
import ImageIO
import MobileCoreServices
import CoreLocation
import CoreMotion
import CoreImage

public enum CameraState {
    case ready, accessDenied, noDeviceFound, notDetermined
}

public enum CameraDevice {
    case front, back
}

public enum CameraFlashMode: Int {
    case off, on, auto
}

//public enum CameraOutputMode {
//    case stillImage, videoWithMic, videoOnly
//}

public enum CameraOutputQuality: Int {
    case low, medium, high
}


/// Class for handling iDevices custom camera usage
open class CameraManager: NSObject, AVCaptureFileOutputRecordingDelegate, UIGestureRecognizerDelegate {
    
    // MARK: - Public properties
    
    // Property for custom image album name.
    open var imageAlbumName: String?
    
    // Property for custom image album name.
    open var videoAlbumName: String?
    
    /// Property for capture session to customize camera settings.
    open var captureSession: AVCaptureSession?
    
    open var hasRunningSession: Bool {
        return captureSession?.isRunning ?? false
    }
    
    /**
     Property to determine if the manager should show the error for the user. If you want to show the errors yourself set this to false. If you want to add custom error UI set showErrorBlock property.
     - note: Default value is **false**
     */
    open var showErrorsToUsers = false
    
    /// Property to determine if the manager should show the camera permission popup immediatly when it's needed or you want to show it manually. Default value is true. Be carful cause using the camera requires permission, if you set this value to false and don't ask manually you won't be able to use the camera.
    open var showAccessPermissionPopupAutomatically = true
    
    /// A block creating UI to present error message to the user. This can be customised to be presented on the Window root view controller, or to pass in the viewController which will present the UIAlertController, for example.
    open var showErrorBlock:(_ erTitle: String, _ erMessage: String) -> Void = { (erTitle: String, erMessage: String) -> Void in
        
        var alertController = UIAlertController(title: erTitle, message: erMessage, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default))
        
        if let topController = UIApplication.topViewController() {
            topController.present(alertController, animated: true)
        }
    }
    
    /**
     Property to determine if manager should write the resources to the phone library.
     - note: Default value is **true**
     */
//    open var writeFilesToPhoneLibrary = true
    
    /**
     Property to determine if manager should follow device orientation.
     - note: Default value is **true**
     */
    open var shouldRespondToOrientationChanges = true {
        didSet {
            if shouldRespondToOrientationChanges {
                _startFollowingDeviceOrientation()
            } else {
                _stopFollowingDeviceOrientation()
            }
        }
    }
    
    /**
     Property to determine if manager should horizontally flip image took by front camera.
     - note: Default value is **false**
     */
    open var shouldFlipFrontCameraImage = false
    
    /**
     Property to determine if manager should keep view with the same bounds when the orientation changes.
     - note: Default value is **false**
     */
    open var shouldKeepViewAtOrientationChanges = false
    
    /**
     Property to determine if manager should enable tap to focus on camera preview.
     - note: Default value is **true**
     */
    open var shouldEnableTapToFocus = true {
        didSet {
            focusGesture.isEnabled = shouldEnableTapToFocus
        }
    }
    
    /**
     Property to determine if manager should enable pinch to zoom on camera preview.
     - note: Default value is **true**
     */
    open var shouldEnablePinchToZoom = true {
        didSet {
            zoomGesture.isEnabled = shouldEnablePinchToZoom
        }
    }
    
    /**
     Property to determine if manager should enable pan to change exposure/brightness.
     - note: Default value is **true**
     */
    open var shouldEnableExposure = true {
        didSet {
            exposureGesture.isEnabled = shouldEnableExposure
        }
    }
    
    /// Property to determine if the camera is ready to use.
    open var cameraIsReady: Bool {
        get {
            return cameraIsSetup
        }
    }
    
    /// Property to determine if current device has front camera.
    open var hasFrontCamera: Bool = {
        let frontDevices = AVCaptureDevice.videoDevices.filter { $0.position == .front }
        return !frontDevices.isEmpty
    }()
    
    /// Property to determine if current device has flash.
    open var hasFlash: Bool = {
        let hasFlashDevices = AVCaptureDevice.videoDevices.filter { $0.hasFlash }
        return !hasFlashDevices.isEmpty
    }()
    
    /**
     Property to enable or disable flip animation when switch between back and front camera.
     - note: Default value is **true**
     */
    open var animateCameraDeviceChange: Bool = true
    
    /**
     Property to enable or disable shutter animation when taking a picture.
     - note: Default value is **true**
     */
    open var animateShutter: Bool = true
    
    /// Property to change camera device between front and back.
    open var cameraDevice = CameraDevice.back {
        didSet {
            if cameraIsSetup && cameraDevice != oldValue {
                if animateCameraDeviceChange {
                    _doFlipAnimation()
                }
                _updateCameraDevice(cameraDevice)
                _updateIlluminationMode(flashMode)
                _setupMaxZoomScale()
                _zoom(0)
                _orientationChanged()
            }
        }
    }
    
    /// Property to change camera flash mode.
    open var flashMode = CameraFlashMode.off {
        didSet {
            if cameraIsSetup && flashMode != oldValue {
                _updateIlluminationMode(flashMode)
            }
        }
    }
    
    /// Property to change camera output quality.
    open var cameraOutputQuality = CameraOutputQuality.high {
        didSet {
            if cameraIsSetup && cameraOutputQuality != oldValue {
                _updateCameraQualityMode(cameraOutputQuality)
            }
        }
    }
    
    /// Property to check video recording duration when in progress.
    open var recordedDuration : CMTime { return movieOutput?.recordedDuration ?? CMTime.zero }
    
    /// Property to check video recording file size when in progress.
    open var recordedFileSize : Int64 { return movieOutput?.recordedFileSize ?? 0 }
    
    /// Property to set focus mode when tap to focus is used (_focusStart).
    open var focusMode : AVCaptureDevice.FocusMode = .continuousAutoFocus
    
    /// Property to set exposure mode when tap to focus is used (_focusStart).
    open var exposureMode: AVCaptureDevice.ExposureMode = .continuousAutoExposure
    
    /// Property to set video stabilisation mode during a video record session
    open var videoStabilisationMode : AVCaptureVideoStabilizationMode = .auto
    
    
    // MARK: - Private properties
    
    fileprivate weak var embeddingView: UIView?
    fileprivate var videoCompletion: ((_ videoURL: URL?, _ error: Error?) -> Void)?
    var createSessionFailureBlock: () -> Void = {}
    
    fileprivate var sessionQueue: DispatchQueue = DispatchQueue(label: "CameraSessionQueue", qos: .userInitiated)
    
    fileprivate lazy var frontCameraDevice: AVCaptureDevice? = {
        return AVCaptureDevice.videoDevices.filter { $0.position == .front }.first
    }()
    
    fileprivate lazy var backCameraDevice: AVCaptureDevice? = {
        return AVCaptureDevice.videoDevices.filter { $0.position == .back }.first
    }()
    
    fileprivate lazy var mic: AVCaptureDevice? = {
        return AVCaptureDevice.default(for: AVMediaType.audio)
    }()
    
    fileprivate var stillImageOutput: AVCaptureStillImageOutput?
    fileprivate var movieOutput: AVCaptureMovieFileOutput?
    fileprivate var previewLayer: AVCaptureVideoPreviewLayer?
    fileprivate var library: PHPhotoLibrary?
    
    fileprivate var cameraIsSetup = false
    fileprivate var cameraIsObservingDeviceOrientation = false
    
    fileprivate var zoomScale       = CGFloat(1.0)
    fileprivate var beginZoomScale  = CGFloat(1.0)
    fileprivate var maxZoomScale    = CGFloat(1.0)
    
    fileprivate func _tempFilePath() -> URL {
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("tempMovie\(Date().timeIntervalSince1970)").appendingPathExtension("mp4")
        return tempURL
    }
    
    fileprivate var coreMotionManager: CMMotionManager!
    
    /// Real device orientation from accelerometer
    fileprivate var deviceOrientation: UIDeviceOrientation = .portrait
    
    // MARK: - CameraManager
    
    /**
     Inits a capture session and adds a preview layer to the given view. Preview layer bounds will automaticaly be set to match given view. Default session is initialized with still image output.
     
     :param: view The view you want to add the preview layer to
     :param: cameraOutputMode The mode you want capturesession to run image / video / video and microphone
     :param: completion Optional completion block
     
     :returns: Current state of the camera: Ready / AccessDenied / NoDeviceFound / NotDetermined.
     */
  
    @discardableResult open func addPreviewLayerToView(_ view: UIView) -> CameraState {
        return addLayerPreviewToView(view, completion: nil)
    }
    
    open func resetLayerPreview() {
        self.embeddingView = nil
    }

    @discardableResult open func addLayerPreviewToView(_ view: UIView, completion: (() -> Void)?) -> CameraState {
        if _canLoadCamera() {
            if let _ = embeddingView {
                if let validPreviewLayer = previewLayer {
                    validPreviewLayer.removeFromSuperlayer()
                }
            }
            
            if cameraIsSetup {
                _addPreviewLayerToView(view)
                if let validCompletion = completion {
                    validCompletion()
                }
            } else {
                _setupCamera {
                    self._addPreviewLayerToView(view)
                    if let validCompletion = completion {
                        validCompletion()
                    }
                }
            }
        }
        
        return _checkIfCameraIsAvailable()
    }

    /**
     Zoom in to the requested scale.
    */
    open func zoom(_ scale: CGFloat) {
        _zoom(scale)
    }
    
    /**
     Asks the user for camera permissions. Only works if the permissions are not yet determined. Note that it'll also automaticaly ask about the microphone permissions if you selected VideoWithMic output.
     
     :param: completion Completion block with the result of permission request
     */
    open func askUserForCameraPermission(_ completion: @escaping (Bool) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            DispatchQueue.main.async {
                completion(true)
            }
        case .notDetermined: // The user has not yet been asked for camera access.
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    AVCaptureDevice.requestAccess(for: AVMediaType.audio) { allowedAccess in
                        DispatchQueue.main.async {
                            completion(allowedAccess)
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        completion(false)
                    }
                }
            }
            
        case .denied, .restricted: // The user has previously denied access.
            DispatchQueue.main.async {
                completion(false)
            }
        }
        
//        AVCaptureDevice.requestAccess(for: AVMediaType.video) { allowedAccess in
//            AVCaptureDevice.requestAccess(for: AVMediaType.audio) { allowedAccess in
//                DispatchQueue.main.async {
//                    completion(allowedAccess)
//                }
//            }
//        }
    }
    
    /**
     Stops running capture session but all setup devices, inputs and outputs stay for further reuse.
     */
    open func stopCaptureSession() {
        captureSession?.stopRunning()
        _stopFollowingDeviceOrientation()
    }
    
    /**
     Resumes capture session.
     */
    open func resumeCaptureSession() {
        if let validCaptureSession = captureSession {
            if !validCaptureSession.isRunning && cameraIsSetup {
                self.sessionQueue.async(execute: {
                    validCaptureSession.startRunning()
                    self._startFollowingDeviceOrientation()
                })
            }
        } else {
            if _canLoadCamera() {
                if cameraIsSetup {
                    stopAndRemoveCaptureSession()
                }
                _setupCamera {
                    if let validEmbeddingView = self.embeddingView {
                        self._addPreviewLayerToView(validEmbeddingView)
                    }
                    self._startFollowingDeviceOrientation()
                }
            }
        }
    }
    
    /**
     Stops running capture session and removes all setup devices, inputs and outputs.
     */
    open func stopAndRemoveCaptureSession() {
        self.stopCaptureSession()
        let oldAnimationValue = self.animateCameraDeviceChange
        self.animateCameraDeviceChange = false
        self.cameraDevice = .back
        self.cameraIsSetup = false
        self.previewLayer = nil
        self.captureSession = nil
        self.frontCameraDevice = nil
        self.backCameraDevice = nil
        self.mic = nil
        self.stillImageOutput = nil
        self.movieOutput = nil
        self.animateCameraDeviceChange = oldAnimationValue
    }
   
//    fileprivate func _setVideoWithGPS(forLocation location: CLLocation) {
//        let metadata = AVMutableMetadataItem()
//        metadata.keySpace = AVMetadataKeySpace.quickTimeMetadata
//        metadata.key = AVMetadataKey.quickTimeMetadataKeyLocationISO6709 as NSString
//        metadata.identifier = AVMetadataIdentifier.quickTimeMetadataLocationISO6709
//        metadata.value = String(format: "%+09.5f%+010.5f%+.0fCRSWGS_84", location.coordinate.latitude, location.coordinate.longitude, location.altitude) as NSString
//        _getMovieOutput().metadata = [metadata]
//    }
    
//    fileprivate func _gpsMetadata(withLocation location: CLLocation) -> NSMutableDictionary {
//        let f = DateFormatter()
//        f.timeZone = TimeZone(abbreviation: "UTC")
//
//        f.dateFormat = "yyyy:MM:dd"
//        let isoDate = f.string(from: location.timestamp)
//
//        f.dateFormat = "HH:mm:ss.SSSSSS"
//        let isoTime = f.string(from: location.timestamp)
//
//        let GPSMetadata = NSMutableDictionary()
//        let altitudeRef = Int(location.altitude < 0.0 ? 1 : 0)
//        let latitudeRef = location.coordinate.latitude < 0.0 ? "S" : "N"
//        let longitudeRef = location.coordinate.longitude < 0.0 ? "W" : "E"
//
//        // GPS metadata
//        GPSMetadata[(kCGImagePropertyGPSLatitude as String)] = abs(location.coordinate.latitude)
//        GPSMetadata[(kCGImagePropertyGPSLongitude as String)] = abs(location.coordinate.longitude)
//        GPSMetadata[(kCGImagePropertyGPSLatitudeRef as String)] = latitudeRef
//        GPSMetadata[(kCGImagePropertyGPSLongitudeRef as String)] = longitudeRef
//        GPSMetadata[(kCGImagePropertyGPSAltitude as String)] = Int(abs(location.altitude))
//        GPSMetadata[(kCGImagePropertyGPSAltitudeRef as String)] = altitudeRef
//        GPSMetadata[(kCGImagePropertyGPSTimeStamp as String)] = isoTime
//        GPSMetadata[(kCGImagePropertyGPSDateStamp as String)] = isoDate
//
//        return GPSMetadata
//    }
   
    fileprivate func _imageOrientation(forDeviceOrientation deviceOrientation: UIDeviceOrientation, isMirrored: Bool) -> UIImage.Orientation {
        
        switch deviceOrientation {
        case .landscapeLeft:
            return isMirrored ? .upMirrored : .up
        case .landscapeRight:
            return isMirrored ? .downMirrored : .down
        default:
            break
        }

        return isMirrored ? .leftMirrored : .right
    }
    
    /**
     Starts recording a video with or without voice as in the session preset.
     */
    open func startRecordingVideo() {
        let videoOutput = _getMovieOutput()
        // setup video mirroring
        for connection in videoOutput.connections {
            for port in connection.inputPorts {
                
                if port.mediaType == AVMediaType.video {
                    let videoConnection = connection as AVCaptureConnection
                    if videoConnection.isVideoMirroringSupported {
                        videoConnection.isVideoMirrored = (cameraDevice == CameraDevice.front && shouldFlipFrontCameraImage)
                    }
                    
                    if videoConnection.isVideoStabilizationSupported {
                        videoConnection.preferredVideoStabilizationMode = self.videoStabilisationMode
                    }
                }
            }
        }
        
        let specs = [kCMMetadataFormatDescriptionMetadataSpecificationKey_Identifier as String: AVMetadataIdentifier.quickTimeMetadataLocationISO6709,
                     kCMMetadataFormatDescriptionMetadataSpecificationKey_DataType as String: kCMMetadataDataType_QuickTimeMetadataLocation_ISO6709 as String] as [String : Any]
        
        var locationMetadataDesc: CMFormatDescription?
        CMMetadataFormatDescriptionCreateWithMetadataSpecifications(allocator: kCFAllocatorDefault, metadataType: kCMMetadataFormatType_Boxed, metadataSpecifications: [specs] as CFArray, formatDescriptionOut: &locationMetadataDesc)
        
        // Create the metadata input and add it to the session.
        guard let captureSession = captureSession, let locationMetadata = locationMetadataDesc else {
            createSessionFailureBlock()
            return
        }

        let newLocationMetadataInput = AVCaptureMetadataInput(formatDescription: locationMetadata, clock: CMClockGetHostTimeClock())
        captureSession.addInputWithNoConnections(newLocationMetadataInput)
        
        // Connect the location metadata input to the movie file output.
        let inputPort = newLocationMetadataInput.ports[0]
        captureSession.addConnection(AVCaptureConnection(inputPorts: [inputPort], output: videoOutput))
        
        _updateIlluminationMode(flashMode)
        
        videoOutput.startRecording(to: _tempFilePath(), recordingDelegate: self)
    }
    
    /**
     Stop recording a video. Save it to the cameraRoll and give back the url.
     */
    open func stopVideoRecording(_ completion: ((_ videoURL: URL?, _ error: Error?) -> Void)?) {
        if let runningMovieOutput = movieOutput, runningMovieOutput.isRecording {
            videoCompletion = completion
            runningMovieOutput.stopRecording()
        } else {
            
            self.movieOutput?.stopRecording()
            
            completion?(nil, nil)
        }
    }
    
    /**
     Check if the device rotation is locked
     */
    open func deviceOrientationMatchesInterfaceOrientation() -> Bool {
        return deviceOrientation == UIDevice.current.orientation
    }
    
    /**
     Current camera status.
     
     :returns: Current state of the camera: Ready / AccessDenied / NoDeviceFound / NotDetermined
     */
    open func currentCameraStatus() -> CameraState {
        return _checkIfCameraIsAvailable()
    }
    
    /**
     Change current flash mode to next value from available ones.
     
     :returns: Current flash mode: Off / On / Auto
     */
    open func changeFlashMode() -> CameraFlashMode {
        guard let newFlashMode = CameraFlashMode(rawValue: (flashMode.rawValue+1)%3) else { return flashMode }
        flashMode = newFlashMode
        return flashMode
    }
    
    /**
     Change current output quality mode to next value from available ones.
     
     :returns: Current quality mode: Low / Medium / High
     */
    open func changeQualityMode() -> CameraOutputQuality {
        guard let newQuality = CameraOutputQuality(rawValue: (cameraOutputQuality.rawValue+1)%3) else { return cameraOutputQuality }
        cameraOutputQuality = newQuality
        return cameraOutputQuality
    }
    
    /**
     Check the camera device has flash
     */
    open func hasFlash(for cameraDevice: CameraDevice) -> Bool {
        let devices = AVCaptureDevice.videoDevices
        for device in devices {
            if device.position == .back && cameraDevice == .back {
                return device.hasFlash
            } else if device.position == .front && cameraDevice == .front {
                return device.hasFlash
            }
        }
        return false
    }
    
    // MARK: - AVCaptureFileOutputRecordingDelegate
    public func fileOutput(captureOutput: AVCaptureFileOutput,
                           didStartRecordingTo fileURL: URL,
                           from connections: [AVCaptureConnection]) {
        
        captureSession?.beginConfiguration()
        if flashMode != .off {
            _updateIlluminationMode(flashMode)
        }
        
        captureSession?.commitConfiguration()
    }
    
    open func fileOutput(_ captureOutput: AVCaptureFileOutput,
                         didFinishRecordingTo outputFileURL: URL,
                         from connections: [AVCaptureConnection], error: Error?) {
        _executeVideoCompletionWithURL(outputFileURL, error: error)
    }
    
    // MARK: - UIGestureRecognizerDelegate
    fileprivate lazy var zoomGesture = UIPinchGestureRecognizer()
    
    fileprivate func attachZoom(_ view: UIView) {
        DispatchQueue.main.async {
            self.zoomGesture.addTarget(self, action: #selector(CameraManager._zoomStart(_:)))
            view.addGestureRecognizer(self.zoomGesture)
            self.zoomGesture.delegate = self
        }
    }
    
    open func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        
        if gestureRecognizer.isKind(of: UIPinchGestureRecognizer.self) {
            beginZoomScale = zoomScale
        }
        
        return true
    }
    
    @objc fileprivate func _zoomStart(_ recognizer: UIPinchGestureRecognizer) {
        guard let view = embeddingView,
            let previewLayer = previewLayer
            else { return }
        
        var allTouchesOnPreviewLayer = true
        let numTouch = recognizer.numberOfTouches
        
        for i in 0 ..< numTouch {
            let location = recognizer.location(ofTouch: i, in: view)
            let convertedTouch = previewLayer.convert(location, from: previewLayer.superlayer)
            if !previewLayer.contains(convertedTouch) {
                allTouchesOnPreviewLayer = false
                break
            }
        }
        if allTouchesOnPreviewLayer {
            _zoom(recognizer.scale)
        }
    }
    
    fileprivate func _zoom(_ scale: CGFloat) {
        let device: AVCaptureDevice?
        
        switch cameraDevice {
        case .back:
            device = backCameraDevice
        case .front:
            device = frontCameraDevice
        }
        
        do {
            let captureDevice = device
            try captureDevice?.lockForConfiguration()
            
            zoomScale = max(1.0, min(beginZoomScale * scale, maxZoomScale))
            
            captureDevice?.videoZoomFactor = zoomScale
            
            captureDevice?.unlockForConfiguration()
            
        } catch {
            print("Error locking configuration")
        }
    }
    
    // MARK: - UIGestureRecognizerDelegate
    fileprivate lazy var focusGesture = UITapGestureRecognizer()
    
    fileprivate func attachFocus(_ view: UIView) {
        DispatchQueue.main.async {
            self.focusGesture.addTarget(self, action: #selector(CameraManager._focusStart(_:)))
            view.addGestureRecognizer(self.focusGesture)
            self.focusGesture.delegate = self
        }
    }
    
    fileprivate lazy var exposureGesture = UIPanGestureRecognizer()
    
    fileprivate func attachExposure(_ view: UIView) {
        DispatchQueue.main.async {
            self.exposureGesture.addTarget(self, action: #selector(CameraManager._exposureStart(_:)))
            view.addGestureRecognizer(self.exposureGesture)
            self.exposureGesture.delegate = self
        }
    }
    
    @objc fileprivate func _focusStart(_ recognizer: UITapGestureRecognizer) {
        
        let device: AVCaptureDevice?
        
        switch cameraDevice {
        case .back:
            device = backCameraDevice
        case .front:
            device = frontCameraDevice
        }
        
        _changeExposureMode(mode: .continuousAutoExposure)
        translationY = 0
        exposureValue = 0.5
        
        if let validDevice = device,
            let validPreviewLayer = previewLayer,
            let view = recognizer.view
        {
                let pointInPreviewLayer = view.layer.convert(recognizer.location(in: view), to: validPreviewLayer)
                let pointOfInterest = validPreviewLayer.captureDevicePointConverted(fromLayerPoint: pointInPreviewLayer)
                
                do {
                    try validDevice.lockForConfiguration()
                    
                    _showFocusRectangleAtPoint(pointInPreviewLayer, inLayer: validPreviewLayer)
                    
                    if validDevice.isFocusPointOfInterestSupported {
                        validDevice.focusPointOfInterest = pointOfInterest
                    }
                    
                    if  validDevice.isExposurePointOfInterestSupported {
                        validDevice.exposurePointOfInterest = pointOfInterest
                    }
                    
                    if validDevice.isFocusModeSupported(focusMode) {
                        validDevice.focusMode = focusMode
                    }
                    
                    if validDevice.isExposureModeSupported(exposureMode) {
                        validDevice.exposureMode = exposureMode
                    }
                    
                    validDevice.unlockForConfiguration()
                } catch let error {
                    logger.log(error)
                }
        }
    }
    
    fileprivate var lastFocusRectangle:CAShapeLayer? = nil
    fileprivate var lastFocusPoint: CGPoint? = nil
    fileprivate func _showFocusRectangleAtPoint(_ focusPoint: CGPoint, inLayer layer: CALayer, withBrightness brightness: Float? = nil) {
        
        if let lastFocusRectangle = lastFocusRectangle {
            
            lastFocusRectangle.removeFromSuperlayer()
            self.lastFocusRectangle = nil
        }
        
        let size = CGSize(width: 75, height: 75)
        let rect = CGRect(origin: CGPoint(x: focusPoint.x - size.width / 2.0, y: focusPoint.y - size.height / 2.0), size: size)
        
        let endPath = UIBezierPath(rect: rect)
        endPath.move(to: CGPoint(x: rect.minX + size.width / 2.0, y: rect.minY))
        endPath.addLine(to: CGPoint(x: rect.minX + size.width / 2.0, y: rect.minY + 5.0))
        endPath.move(to: CGPoint(x: rect.maxX, y: rect.minY + size.height / 2.0))
        endPath.addLine(to: CGPoint(x: rect.maxX - 5.0, y: rect.minY + size.height / 2.0))
        endPath.move(to: CGPoint(x: rect.minX + size.width / 2.0, y: rect.maxY))
        endPath.addLine(to: CGPoint(x: rect.minX + size.width / 2.0, y: rect.maxY - 5.0))
        endPath.move(to: CGPoint(x: rect.minX, y: rect.minY + size.height / 2.0))
        endPath.addLine(to: CGPoint(x: rect.minX + 5.0, y: rect.minY + size.height / 2.0))
        if (brightness != nil) {
            endPath.move(to: CGPoint(x: rect.minX + size.width + size.width / 4, y: rect.minY))
            endPath.addLine(to: CGPoint(x: rect.minX + size.width + size.width / 4, y: rect.minY + size.height))
            
            endPath.move(to: CGPoint(x: rect.minX + size.width + size.width / 4 - size.width / 16, y: rect.minY + size.height - CGFloat(brightness!) * size.height))
            endPath.addLine(to: CGPoint(x: rect.minX + size.width + size.width / 4 + size.width / 16, y: rect.minY + size.height - CGFloat(brightness!) * size.height))
        }
        
        let startPath = UIBezierPath(cgPath: endPath.cgPath)
        let scaleAroundCenterTransform = CGAffineTransform(translationX: -focusPoint.x, y: -focusPoint.y).concatenating(CGAffineTransform(scaleX: 2.0, y: 2.0).concatenating(CGAffineTransform(translationX: focusPoint.x, y: focusPoint.y)))
        startPath.apply(scaleAroundCenterTransform)
        
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = endPath.cgPath
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.strokeColor = UIColor(red:1, green:0.83, blue:0, alpha:0.95).cgColor
        shapeLayer.lineWidth = 1.0
        
        layer.addSublayer(shapeLayer)
        lastFocusRectangle = shapeLayer
        lastFocusPoint = focusPoint
        
        CATransaction.begin()
        
        CATransaction.setAnimationDuration(0.2)
        CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeOut))
        
        CATransaction.setCompletionBlock {
            if shapeLayer.superlayer != nil {
                shapeLayer.removeFromSuperlayer()
                self.lastFocusRectangle = nil
            }
        }
        if (brightness == nil) {
            let appearPathAnimation = CABasicAnimation(keyPath: "path")
            appearPathAnimation.fromValue = startPath.cgPath
            appearPathAnimation.toValue = endPath.cgPath
            shapeLayer.add(appearPathAnimation, forKey: "path")
            
            let appearOpacityAnimation = CABasicAnimation(keyPath: "opacity")
            appearOpacityAnimation.fromValue = 0.0
            appearOpacityAnimation.toValue = 1.0
            shapeLayer.add(appearOpacityAnimation, forKey: "opacity")
        }
        
        let disappearOpacityAnimation = CABasicAnimation(keyPath: "opacity")
        disappearOpacityAnimation.fromValue = 1.0
        disappearOpacityAnimation.toValue = 0.0
        disappearOpacityAnimation.beginTime = CACurrentMediaTime() + 0.8
        disappearOpacityAnimation.fillMode = CAMediaTimingFillMode.forwards
        disappearOpacityAnimation.isRemovedOnCompletion = false
        shapeLayer.add(disappearOpacityAnimation, forKey: "opacity")
        
        CATransaction.commit()
    }
    
    var exposureValue: Float = 0.1 // EV
    var translationY: Float = 0
    var startPanPointInPreviewLayer: CGPoint?
    
    let exposureDurationPower:Float = 4.0 //the exposure slider gain
    let exposureMininumDuration:Float64 = 1.0/2000.0
    
    @objc fileprivate func _exposureStart(_ gestureRecognizer: UIPanGestureRecognizer) {
        guard gestureRecognizer.view != nil else {return}
        let view = gestureRecognizer.view!
        
        _changeExposureMode(mode: .custom)
        
        let translation = gestureRecognizer.translation(in: view)
        let currentTranslation = translationY + Float(translation.y)
        if (gestureRecognizer.state == .ended) {
            translationY = currentTranslation
        }
        if (currentTranslation < 0) {
            // up - brighter
            exposureValue = 0.5 + min(abs(currentTranslation) / 400, 1) / 2
        } else if (currentTranslation >= 0) {
            // down - lower
            exposureValue = 0.5 - min(abs(currentTranslation) / 400, 1) / 2
        }
        _changeExposureDuration(value: exposureValue)
        
        // UI Visualization
        if (gestureRecognizer.state == .began) {
            if let validPreviewLayer = previewLayer {
                startPanPointInPreviewLayer = view.layer.convert(gestureRecognizer.location(in: view), to: validPreviewLayer)
            }
        }
        
        if let validPreviewLayer = previewLayer, let lastFocusPoint = self.lastFocusPoint {
            _showFocusRectangleAtPoint(lastFocusPoint, inLayer: validPreviewLayer, withBrightness: exposureValue)
        }
    }
    
    // Available modes:
    // .Locked .AutoExpose .ContinuousAutoExposure .Custom
    func _changeExposureMode(mode: AVCaptureDevice.ExposureMode) {
        let device: AVCaptureDevice?
        
        switch cameraDevice {
        case .back:
            device = backCameraDevice
        case .front:
            device = frontCameraDevice
        }
        if (device?.exposureMode == mode) {
            return
        }
        
        do {
            try device?.lockForConfiguration()
        } catch {
            return
        }
        if device?.isExposureModeSupported(mode) == true {
            device?.exposureMode = mode
        }
        device?.unlockForConfiguration()
    }
    
    func _changeExposureDuration(value: Float) {
        if (self.cameraIsSetup) {
            let device: AVCaptureDevice?
            
            switch cameraDevice {
            case .back:
                device = backCameraDevice
            case .front:
                device = frontCameraDevice
            }
            
            do {
                try device?.lockForConfiguration()
            } catch {
                return
            }
            guard let videoDevice = device else {
                return
            }
            
            let p = Float64(pow(value, exposureDurationPower)) // Apply power function to expand slider's low-end range
            let minDurationSeconds = Float64(max(CMTimeGetSeconds(videoDevice.activeFormat.minExposureDuration), exposureMininumDuration))
            let maxDurationSeconds = Float64(CMTimeGetSeconds(videoDevice.activeFormat.maxExposureDuration))
            let newDurationSeconds = Float64(p * (maxDurationSeconds - minDurationSeconds)) + minDurationSeconds // Scale from 0-1 slider range to actual duration
            
            if (videoDevice.exposureMode == .custom) {
                let newExposureTime = CMTimeMakeWithSeconds(Float64(newDurationSeconds), preferredTimescale: 1000*1000*1000)
                videoDevice.setExposureModeCustom(duration: newExposureTime, iso: AVCaptureDevice.currentISO, completionHandler: nil)
            }
        }
    }

    
    // MARK: - CameraManager()
    
    fileprivate func _executeVideoCompletionWithURL(_ url: URL?, error: Error?) {
        if let validCompletion = videoCompletion {
            validCompletion(url, error)
            videoCompletion = nil
        }
    }
    
    fileprivate func _getMovieOutput() -> AVCaptureMovieFileOutput {
        if movieOutput == nil {
            let newMoviewOutput = AVCaptureMovieFileOutput()
            newMoviewOutput.movieFragmentInterval = CMTime.invalid
            movieOutput = newMoviewOutput
            if let captureSession = captureSession {
                if captureSession.canAddOutput(newMoviewOutput) {
                    captureSession.beginConfiguration()
                    captureSession.addOutput(newMoviewOutput)
                    captureSession.commitConfiguration()
                }
            }
        }

        return movieOutput!
    }
    
    @objc fileprivate func _orientationChanged() {
        let currentConnection = _getMovieOutput().connection(with: AVMediaType.video)
        
        if let validPreviewLayer = previewLayer {
            if !shouldKeepViewAtOrientationChanges {
                if let validPreviewLayerConnection = validPreviewLayer.connection, validPreviewLayerConnection.isVideoOrientationSupported {
                        validPreviewLayerConnection.videoOrientation = _currentPreviewVideoOrientation()
                }
            }
            if let validOutputLayerConnection = currentConnection,
                validOutputLayerConnection.isVideoOrientationSupported {
                
                validOutputLayerConnection.videoOrientation = _currentCaptureVideoOrientation()
            }
            if !shouldKeepViewAtOrientationChanges && cameraIsObservingDeviceOrientation {
                DispatchQueue.main.async {
                    if let validEmbeddingView = self.embeddingView {
                        validPreviewLayer.frame = validEmbeddingView.bounds
                    }
                }
            }
        }
    }
    
    fileprivate func _currentCaptureVideoOrientation() -> AVCaptureVideoOrientation {
        if deviceOrientation == .faceDown || deviceOrientation == .faceUp || deviceOrientation == .unknown {
             return _currentPreviewVideoOrientation()
        }
        
        return _videoOrientation(forDeviceOrientation: deviceOrientation)
    }
    
    
    fileprivate func _currentPreviewDeviceOrientation() -> UIDeviceOrientation {
        if shouldKeepViewAtOrientationChanges {
            return .portrait
        }
        
        return UIDevice.current.orientation
    }

    
    fileprivate func _currentPreviewVideoOrientation() -> AVCaptureVideoOrientation {
        let orientation = _currentPreviewDeviceOrientation()
        return _videoOrientation(forDeviceOrientation: orientation)
    }
    
    open func resetOrientation() {
        //Main purpose is to reset the preview layer orientation.  Problems occur if you are recording landscape, present a modal VC,
        //then turn portriat to dismiss.  The preview view is then stuck in a prior orientation and not redrawn.  Calling this function
        //will then update the orientation of the preview layer.
        _orientationChanged()
    }

    fileprivate func _videoOrientation(forDeviceOrientation deviceOrientation: UIDeviceOrientation) -> AVCaptureVideoOrientation {
        switch deviceOrientation {
        case .landscapeLeft:
            return .landscapeRight
        case .landscapeRight:
            return .landscapeLeft
        case .portraitUpsideDown:
            return .portraitUpsideDown
        case .faceUp:
            /*
             Attempt to keep the existing orientation.  If the device was landscape, then face up
             getting the orientation from the stats bar would fail every other time forcing it
             to default to portrait which would introduce flicker into the preview layer.  This
             would not happen if it was in portrait then face up
            */
            if let validPreviewLayer = previewLayer, let connection = validPreviewLayer.connection  {
                return connection.videoOrientation //Keep the existing orientation
            }
            //Could not get existing orientation, try to get it from stats bar
            return _videoOrientationFromStatusBarOrientation()
        case .faceDown:
            /*
             Attempt to keep the existing orientation.  If the device was landscape, then face down
             getting the orientation from the stats bar would fail every other time forcing it
             to default to portrait which would introduce flicker into the preview layer.  This
             would not happen if it was in portrait then face down
             */
            if let validPreviewLayer = previewLayer, let connection = validPreviewLayer.connection  {
                return connection.videoOrientation //Keep the existing orientation
            }
            //Could not get existing orientation, try to get it from stats bar
            return _videoOrientationFromStatusBarOrientation()
        default:
            return .portrait
        }
    }
    
    fileprivate func _videoOrientationFromStatusBarOrientation() -> AVCaptureVideoOrientation {
        
        var orientation: UIInterfaceOrientation?
       
        DispatchQueue.main.async {
            orientation = UIApplication.shared.statusBarOrientation
        }
        
        /*
         Note - the following would fall into the guard every other call (it is called repeatedly) if the device was
         landscape then face up/down.  Did not seem to fail if in portrait first.
         */
        guard let statusBarOrientation = orientation else {
            return .portrait
        }
        
        switch statusBarOrientation {
        case .landscapeLeft:
            return .landscapeLeft
        case .landscapeRight:
            return .landscapeRight
        case .portrait:
            return .portrait
        case .portraitUpsideDown:
            return .portraitUpsideDown
        default:
            return .portrait
        }
    }
    
    fileprivate func fixOrientation(withImage image: UIImage) -> UIImage {
        guard let cgImage = image.cgImage else { return image }
        
        var isMirrored = false
        let orientation = image.imageOrientation
        if orientation == .rightMirrored
            || orientation == .leftMirrored
            || orientation == .upMirrored
            || orientation == .downMirrored {
            
            isMirrored = true
        }
        
        let newOrientation = _imageOrientation(forDeviceOrientation: deviceOrientation, isMirrored: isMirrored)
        
        if image.imageOrientation != newOrientation {
            return UIImage(cgImage: cgImage, scale: image.scale, orientation: newOrientation)
        }
        
        return image
    }
    
    fileprivate func _canLoadCamera() -> Bool {
        let currentCameraState = _checkIfCameraIsAvailable()
        return currentCameraState == .ready || (currentCameraState == .notDetermined && showAccessPermissionPopupAutomatically)
    }
    
    fileprivate func _setupCamera(_ completion: @escaping () -> Void) {
        captureSession = AVCaptureSession()
        
        if let validCaptureSession = self.captureSession {
            validCaptureSession.beginConfiguration()
            validCaptureSession.sessionPreset = AVCaptureSession.Preset.high
            
            self._updateCameraDevice(self.cameraDevice)
            
            self._setupOutputs()
            self._setupOutputMode()
            self._setupPreviewLayer()
            
            validCaptureSession.commitConfiguration()
            self._updateIlluminationMode(self.flashMode)
            self._updateCameraQualityMode(self.cameraOutputQuality)
            validCaptureSession.startRunning()
            
            self._startFollowingDeviceOrientation()
            self.cameraIsSetup = true
            self._orientationChanged()
            
            completion()
        }
    }
    
    fileprivate func _startFollowingDeviceOrientation() {
        if shouldRespondToOrientationChanges && !cameraIsObservingDeviceOrientation {
            coreMotionManager = CMMotionManager()
            coreMotionManager.accelerometerUpdateInterval = 0.005
            
            if coreMotionManager.isAccelerometerAvailable {
                coreMotionManager.startAccelerometerUpdates(to: OperationQueue(), withHandler:
                    {data, error in
                        
                        guard let acceleration: CMAcceleration = data?.acceleration  else{
                            return
                        }
                        
                        let scaling: CGFloat = CGFloat(1) / CGFloat(( abs(acceleration.x) + abs(acceleration.y)))
                        
                        let x: CGFloat = CGFloat(acceleration.x) * scaling
                        let y: CGFloat = CGFloat(acceleration.y) * scaling
                        
                        if acceleration.z < Double(-0.75) {
                            self.deviceOrientation = .faceUp
                        } else if acceleration.z > Double(0.75) {
                            self.deviceOrientation = .faceDown
                        } else if x < CGFloat(-0.5) {
                            self.deviceOrientation = .landscapeLeft
                        } else if x > CGFloat(0.5) {
                            self.deviceOrientation = .landscapeRight
                        } else if y > CGFloat(0.5) {
                            self.deviceOrientation = .portraitUpsideDown
                        }
                        
                        self._orientationChanged()
                })
                
                cameraIsObservingDeviceOrientation = true
            } else {
                cameraIsObservingDeviceOrientation = false
            }
        }
    }
    
    fileprivate func updateDeviceOrientation(_ orientaion: UIDeviceOrientation) {
        self.deviceOrientation = orientaion
    }
    
    fileprivate func _stopFollowingDeviceOrientation() {
        if cameraIsObservingDeviceOrientation {
            coreMotionManager.stopAccelerometerUpdates()
            cameraIsObservingDeviceOrientation = false
        }
    }
    
    fileprivate func _addPreviewLayerToView(_ view: UIView) {
        embeddingView = view
        attachZoom(view)
        attachFocus(view)
        attachExposure(view)
        
        DispatchQueue.main.async(execute: { () -> Void in
            guard let previewLayer = self.previewLayer else { return }
            previewLayer.frame = view.layer.bounds
            view.clipsToBounds = true
            view.layer.addSublayer(previewLayer)
        })
    }
    
    fileprivate func _setupMaxZoomScale() {
        var maxZoom = CGFloat(1.0)
        beginZoomScale = CGFloat(1.0)
        
        if cameraDevice == .back, let backCameraDevice = backCameraDevice  {
            maxZoom = backCameraDevice.activeFormat.videoMaxZoomFactor
        } else if cameraDevice == .front, let frontCameraDevice = frontCameraDevice {
            maxZoom = frontCameraDevice.activeFormat.videoMaxZoomFactor
        }
        
        maxZoomScale = maxZoom
    }
    
    fileprivate func _checkIfCameraIsAvailable() -> CameraState {
        let deviceHasCamera = UIImagePickerController.isCameraDeviceAvailable(.rear) || UIImagePickerController.isCameraDeviceAvailable(.front)
        if deviceHasCamera {
            let authorizationStatus = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
            let userAgreedToUseIt = authorizationStatus == .authorized
            if userAgreedToUseIt {
                return .ready
            } else if authorizationStatus == AVAuthorizationStatus.notDetermined {
                return .notDetermined
            } else {
                _show(NSLocalizedString("Camera access denied", comment:""), message:NSLocalizedString("You need to go to settings app and grant access to the camera device to use it.", comment:""))
                return .accessDenied
            }
        } else {
            _show(NSLocalizedString("Camera unavailable", comment:""), message:NSLocalizedString("The device does not have a camera.", comment:""))
            return .noDeviceFound
        }
    }
    
    fileprivate func _setupOutputMode() {
        captureSession?.beginConfiguration()
        
        if let validMovieOutput = movieOutput {
            captureSession?.removeOutput(validMovieOutput)
            _removeMicInput()
        }
        
        let videoMovieOutput = _getMovieOutput()
        if let captureSession = captureSession, captureSession.canAddOutput(videoMovieOutput) {
            captureSession.addOutput(videoMovieOutput)
        }
        
        let micDevice = _deviceInputFromDevice(mic) { error in
            if let _ = error {
            _show(NSLocalizedString("Camera access denied", comment:""),
                  message: NSLocalizedString("You need to go to settings app and grant access to the microphone device to use it.", comment:"")
                )
            }
        }
        
        if let validMic = micDevice {
            captureSession?.addInput(validMic)
        }
        
        captureSession?.commitConfiguration()
        _updateCameraQualityMode(cameraOutputQuality)
        _orientationChanged()
    }
    
    fileprivate func _setupOutputs() {
        if stillImageOutput == nil {
            stillImageOutput = AVCaptureStillImageOutput()
        }
        if movieOutput == nil {
            movieOutput = AVCaptureMovieFileOutput()
            movieOutput?.movieFragmentInterval = CMTime.invalid
        }
        if library == nil {
            library = PHPhotoLibrary.shared()
        }
    }
    
    fileprivate func _setupPreviewLayer() {
        if let validCaptureSession = captureSession {
            previewLayer = AVCaptureVideoPreviewLayer(session: validCaptureSession)
            previewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        }
    }
    
    /**
     Switches between the current and specified camera using a flip animation similar to the one used in the iOS stock camera app.
     */
    
    fileprivate var cameraTransitionView: UIView?
    fileprivate var transitionAnimating = false
    
    open func _doFlipAnimation() {
        
        if transitionAnimating {
            return
        }
        
        if let validEmbeddingView = embeddingView,
            let validPreviewLayer = previewLayer {
                var tempView = UIView()
                
                if CameraManager._blurSupported() {
                    let blurEffect = UIBlurEffect(style: .light)
                    tempView = UIVisualEffectView(effect: blurEffect)
                    tempView.frame = validEmbeddingView.bounds
                } else {
                    tempView = UIView(frame: validEmbeddingView.bounds)
                    tempView.backgroundColor = UIColor(white: 0.0, alpha: 0.5)
                }
                
                validEmbeddingView.insertSubview(tempView, at: Int(validPreviewLayer.zPosition + 1))
                
                cameraTransitionView = validEmbeddingView.snapshotView(afterScreenUpdates: true)
                
                if let cameraTransitionView = cameraTransitionView {
                    validEmbeddingView.insertSubview(cameraTransitionView, at: Int(validEmbeddingView.layer.zPosition + 1))
                }
                tempView.removeFromSuperview()
                
                transitionAnimating = true
                
                validPreviewLayer.opacity = 0.0
                
                DispatchQueue.main.async {
                    self._flipCameraTransitionView()
                }
        }
    }
   
    fileprivate class func _blurSupported() -> Bool {
        var supported = Set<String>()
        supported.insert("iPad")
        supported.insert("iPad1,1")
        supported.insert("iPhone1,1")
        supported.insert("iPhone1,2")
        supported.insert("iPhone2,1")
        supported.insert("iPhone3,1")
        supported.insert("iPhone3,2")
        supported.insert("iPhone3,3")
        supported.insert("iPod1,1")
        supported.insert("iPod2,1")
        supported.insert("iPod2,2")
        supported.insert("iPod3,1")
        supported.insert("iPod4,1")
        supported.insert("iPad2,1")
        supported.insert("iPad2,2")
        supported.insert("iPad2,3")
        supported.insert("iPad2,4")
        supported.insert("iPad3,1")
        supported.insert("iPad3,2")
        supported.insert("iPad3,3")
        
        return !supported.contains(_hardwareString())
    }
    
    fileprivate class func _hardwareString() -> String {
        var sysinfo = utsname()
        uname(&sysinfo)
        guard let deviceName = String(bytes: Data(bytes: &sysinfo.machine, count: Int(_SYS_NAMELEN)), encoding: .ascii)?.trimmingCharacters(in: .controlCharacters) else {
            return ""
        }
        return deviceName
    }
    
    fileprivate func _flipCameraTransitionView() {
        
        if let cameraTransitionView = cameraTransitionView {
            
            UIView.transition(with: cameraTransitionView,
                              duration: 0.5,
                              options: UIView.AnimationOptions.transitionFlipFromLeft,
                              animations: nil,
                              completion: { (_) -> Void in
                                self._removeCameraTransistionView()
            })
        }
    }
    
    fileprivate func _removeCameraTransistionView() {
        
        if let cameraTransitionView = cameraTransitionView {
            if let validPreviewLayer = previewLayer {
                validPreviewLayer.opacity = 1.0
            }
            
            UIView.animate(withDuration: 0.5,
                           animations: { () -> Void in
                            
                            cameraTransitionView.alpha = 0.0
                            
            }, completion: { (_) -> Void in
                
                self.transitionAnimating = false
                
                cameraTransitionView.removeFromSuperview()
                self.cameraTransitionView = nil
            })
        }
    }
    
    fileprivate func _updateCameraDevice(_ deviceType: CameraDevice) {
        if let validCaptureSession = captureSession {
            validCaptureSession.beginConfiguration()
            defer { validCaptureSession.commitConfiguration() }
            let inputs: [AVCaptureInput] = validCaptureSession.inputs
            
            for input in inputs {
                if let deviceInput = input as? AVCaptureDeviceInput, deviceInput.device != mic {
                    validCaptureSession.removeInput(deviceInput)
                }
            }
            
            switch cameraDevice {
            case .front:
                if hasFrontCamera {
                    let frontDevice = _deviceInputFromDevice(frontCameraDevice) { error in
                        if let occuredError = error {
                            _show(NSLocalizedString("Device setup error occured", comment:""), message: "\(occuredError.localizedDescription)")
                        }
                    }
                    
                    if let validFrontDevice = frontDevice, !inputs.contains(validFrontDevice) {
                        validCaptureSession.addInput(validFrontDevice)
                    }
                }
            case .back:
                let backDevice = _deviceInputFromDevice(backCameraDevice) { error in
                    if let occuredError = error {
                        _show(NSLocalizedString("Device setup error occured", comment:""), message: "\(occuredError.localizedDescription)")
                    }
                }
                
                if let validBackDevice = backDevice, !inputs.contains(validBackDevice) {
                    validCaptureSession.addInput(validBackDevice)
                }
            }
        }
    }
    
    fileprivate func _updateIlluminationMode(_ mode: CameraFlashMode) {
        _updateTorch(mode)
    }
    
    fileprivate func _updateTorch(_ torchMode: CameraFlashMode) {
        captureSession?.beginConfiguration()
        
        defer { captureSession?.commitConfiguration() }
        for captureDevice in AVCaptureDevice.videoDevices  {
            guard let avTorchMode = AVCaptureDevice.TorchMode(rawValue: flashMode.rawValue) else { continue }
            if captureDevice.isTorchModeSupported(avTorchMode) && cameraDevice == .back {
                do {
                    try captureDevice.lockForConfiguration()
                } catch {
                    return
                }
                
                captureDevice.torchMode = avTorchMode
                captureDevice.unlockForConfiguration()
            }
        }
    }
    
    fileprivate func _updateFlash(_ flashMode: CameraFlashMode) {
        captureSession?.beginConfiguration()
        defer { captureSession?.commitConfiguration() }
        for captureDevice in AVCaptureDevice.videoDevices  {
            guard let avFlashMode = AVCaptureDevice.FlashMode(rawValue: flashMode.rawValue) else { continue }
            if captureDevice.isFlashModeSupported(avFlashMode) && cameraDevice == .back  {
                do {
                    try captureDevice.lockForConfiguration()
                } catch {
                    return
                }
                
                captureDevice.flashMode = avFlashMode
                captureDevice.unlockForConfiguration()
            }
        }
    }
    
    fileprivate func _performShutterAnimation(_ completion: (() -> Void)?) {
        if let validPreviewLayer = previewLayer {
            DispatchQueue.main.async {
                
                let duration = 0.1
                
                CATransaction.begin()
                
                if let completion = completion {
                    CATransaction.setCompletionBlock(completion)
                }
                
                let fadeOutAnimation = CABasicAnimation(keyPath: "opacity")
                fadeOutAnimation.fromValue = 1.0
                fadeOutAnimation.toValue = 0.0
                validPreviewLayer.add(fadeOutAnimation, forKey: "opacity")
                
                let fadeInAnimation = CABasicAnimation(keyPath: "opacity")
                fadeInAnimation.fromValue = 0.0
                fadeInAnimation.toValue = 1.0
                fadeInAnimation.beginTime = CACurrentMediaTime() + duration * 2.0
                validPreviewLayer.add(fadeInAnimation, forKey: "opacity")
                
                CATransaction.commit()
            }
        }
    }
    
    fileprivate func _updateCameraQualityMode(_ newCameraOutputQuality: CameraOutputQuality) {
        if let validCaptureSession = captureSession {
            var sessionPreset = AVCaptureSession.Preset.low
            switch newCameraOutputQuality {
            case CameraOutputQuality.low:
                sessionPreset = AVCaptureSession.Preset.low
            case CameraOutputQuality.medium:
                sessionPreset = AVCaptureSession.Preset.medium
            case CameraOutputQuality.high:
                sessionPreset = AVCaptureSession.Preset.high
            }
            
            if validCaptureSession.canSetSessionPreset(sessionPreset) {
                validCaptureSession.beginConfiguration()
                validCaptureSession.sessionPreset = sessionPreset
                validCaptureSession.commitConfiguration()
            } else {
                _show(NSLocalizedString("Preset not supported", comment:""), message: NSLocalizedString("Camera preset not supported. Please try another one.", comment:""))
            }
        } else {
            _show(NSLocalizedString("Camera error", comment:""), message: NSLocalizedString("No valid capture session found, I can't take any pictures or videos.", comment:""))
        }
    }
    
    fileprivate func _removeMicInput() {
        guard let inputs = captureSession?.inputs else { return }
        
        for input in inputs {
            if let deviceInput = input as? AVCaptureDeviceInput, deviceInput.device == mic {
                captureSession?.removeInput(deviceInput)
                break
            }
        }
    }
    
    fileprivate func _show(_ title: String, message: String) {
        if showErrorsToUsers {
            DispatchQueue.main.async {
                self.showErrorBlock(title, message)
            }
        }
    }
    
    fileprivate func _deviceInputFromDevice(_ device: AVCaptureDevice?, completion: (Error?) -> Void) -> AVCaptureDeviceInput? {
        guard let validDevice = device else { return nil }
        
        do {
            let device = try AVCaptureDeviceInput(device: validDevice)
            completion(nil)
            
            return device
        } catch let outError {
            completion(outError)
            
            return nil
        }
    }

    deinit {
        _stopFollowingDeviceOrientation()

        self.stopCaptureSession()
        let oldAnimationValue = self.animateCameraDeviceChange
        self.animateCameraDeviceChange = false
        self.cameraIsSetup = false
        self.previewLayer = nil
        self.captureSession = nil
        self.frontCameraDevice = nil
        self.backCameraDevice = nil
        self.mic = nil
        self.stillImageOutput = nil
        self.movieOutput = nil
        self.animateCameraDeviceChange = oldAnimationValue
    }
}

fileprivate extension AVCaptureDevice {
    
    fileprivate static var videoDevices: [AVCaptureDevice] {
        return AVCaptureDevice.devices(for: .video)
    }
    
}
