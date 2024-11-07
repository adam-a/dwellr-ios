import AVFoundation

class CameraService: NSObject, ObservableObject, AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        print("FINISHED: ", outputFileURL)
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        print("STARTED: ", fileURL, output, connections)
    }
    
    let captureSession = AVCaptureSession()
    var movieOutput = AVCaptureMovieFileOutput()
    
    @Published var captureURL: URL?
    func checkCameraAndAudioPermissions() {
        let audioStatus = AVCaptureDevice.authorizationStatus(for: .audio)
        
        switch audioStatus {
        case .authorized:
            // Audio permission already granted.
            checkVideoPermission()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                if granted {
                    DispatchQueue.main.async {
                        self.checkVideoPermission()
                    }
                } else {
                    print("Audio access denied.")
                    // Handle the case where audio permission is denied.
                }
            }
        case .denied, .restricted:
            print("Audio access denied or restricted.")
            // Handle the case where audio permission is denied or restricted.
        @unknown default:
            break
        }
    }
    
    func checkVideoPermission() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch status {
        case .authorized:
            // Video permission already granted.
            if !self.captureSession.isRunning {
                DispatchQueue.main.async {
                    self.setupCaptureSession()
                }
            }
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted && !self.captureSession.isRunning {
                    DispatchQueue.main.async {
                        self.setupCaptureSession()
                    }
                } else {
                    print("Video access denied.")
                    // Handle the case where video permission is denied.
                }
            }
        case .denied, .restricted:
            print("Video access denied or restricted.")
            // Handle the case where video permission is denied or restricted.
        @unknown default:
            break
        }
    }
    
    func setupCaptureSession() {
        guard let camera = AVCaptureDevice.default(for: .video) else {
            fatalError("No camera available")
        }
        
        guard let microphone = AVCaptureDevice.default(for: .audio) else {
            fatalError("No microphone available")
        }
        
        
        do {
            let videoInput = try AVCaptureDeviceInput(device: camera)
            let audioInput = try AVCaptureDeviceInput(device: microphone)
            captureSession.addInput(videoInput)
            captureSession.addInput(audioInput)
            
            if captureSession.canAddOutput(movieOutput) {
                captureSession.addOutput(movieOutput)
            }
            
            let audioOutput = AVCaptureAudioDataOutput()
            if captureSession.canAddOutput(audioOutput) {
                captureSession.addOutput(audioOutput)
            }
            
            if let connection = movieOutput.connection(with: .video) {
                connection.videoOrientation = .portrait
            }
            
            captureSession.sessionPreset = .high
            
            try captureSession.commitConfiguration()
            
            DispatchQueue.global(qos: .background).async {
                self.captureSession.startRunning()
            }
            
        } catch {
            fatalError("Unable to initialize camera: \(error.localizedDescription)")
        }
    }
    
    //todo why is this running when we have no connection? Thus causing the crash
    func startRecording() throws {
        let url = tempURLForVideo()
        print("startRecording called...")
        
        // Check for active connections
        if self.movieOutput.connections.isEmpty {
            setupCaptureSession()
        }
        
        self.movieOutput.startRecording(to: url, recordingDelegate: self)
        
        DispatchQueue.main.async {
            self.captureURL = url
        }
    }
    
    func pauseRecording() {
        print("pauseRecording called...")
        self.movieOutput.stopRecording()
        
    }
    
    func releaseResources() {
        DispatchQueue.global(qos: .background).async {
            for input in self.captureSession.inputs {
                self.captureSession.removeInput(input)
            }
            for output in self.captureSession.outputs {
                self.captureSession.removeOutput(output)
            }
            self.captureSession.stopRunning()
        }
    }
}
