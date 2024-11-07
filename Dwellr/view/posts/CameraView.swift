import SwiftUI

extension String {
    func numberOfOccurrencesOf(string: String) -> Int {
        return self.components(separatedBy:string).count - 1
    }
}

struct CameraView: View {
    @StateObject private var cameraViewModel = CameraService()
    @StateObject var speechRecognizer = SpeechRecognizer()
    
    @State private var didLongPress = false
    @State private var isRecording = false
    @State private var timer: Timer?
    @State private var trackData: [Int: CaptureData] = [:]
    @State private var showAlert = false
    @State private var videoIndex: Int = -1
    @State private var countdown: Int = 60
    @State private var prevCountdown: Int = 60
    @State private var isRecordingInProgress = false
    @Binding var isPresented: Bool
    @State private var persistantKeywodDetection: [String: Int] = [
        "bedroom": 0,
        "living room": 0,
        "washer": 0,
        "dryer": 0,
        "kitchen": 0,
        "bathroom": 0
    ]
    
    @State private var liveKeywordDetection: [String: Bool] = [
        "bedroom": false,
        "living room": false,
        "washer": false,
        "dryer": false,
        "kitchen": false,
        "bathroom": false
    ]
    
    private func binding(for key: String) -> Binding<Int> {
        return .init(
            get: { self.persistantKeywodDetection[key, default: 0] },
            set: { self.persistantKeywodDetection[key] = $0 })
    }
    
    
    private func liveBinding(for key: String) -> Binding<Bool> {
        return .init(
            get: { self.liveKeywordDetection[key, default: false] },
            set: { self.liveKeywordDetection[key] = $0 })
    }
    
    
    private func imageFor(_ keyword: String) -> String {
        switch keyword {
        case "bedroom": return "bed.double"
        case "bed room": return "bed.double"
        case "living room": return "sofa"
        case "washer": return "washer"
        case "dryer": return "dryer"
        case "kitchen": return "oven"
        case "bathroom": return "toilet"
        case "bath room": return "toilet"
        default: return ""
        }
    }
    
    func startTimer() {
        if timer == nil {
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
                if countdown > 0 {
                    countdown -= 1
                } else {
                    stopTimer()
                }
            }
        }
    }
    
    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    
    func stopRecording() {
        DispatchQueue.main.async {
            speechRecognizer.stopTranscribing()
            self.didLongPress = false
            self.isRecording = false
        }
        
        stopTimer()
        if (cameraViewModel.captureURL != nil && self.prevCountdown - self.countdown > 0) {
            self.videoIndex+=1
            trackData[videoIndex] = CaptureData(url: cameraViewModel.captureURL!, transcript: speechRecognizer.transcript.lowercased(), duration: prevCountdown - countdown)
        }
        cameraViewModel.pauseRecording()
        for keyword in persistantKeywodDetection.keys {
            if let currentValue = persistantKeywodDetection[keyword] {
                persistantKeywodDetection[keyword] = currentValue + speechRecognizer.transcript.lowercased().numberOfOccurrencesOf(string: keyword)
            }
            liveKeywordDetection[keyword] = false
        }
    }
    
    func startRecording() {
        do {
            startTimer()
            
            try cameraViewModel.startRecording()
            
            prevCountdown = countdown
            
            DispatchQueue.main.async {
                speechRecognizer.startTranscribing()
                self.didLongPress = true
                self.isRecording = true
            }
        } catch {
            print("startRecording Error", error)
        }
    }
    
    var body: some View {
        ZStack {
            CameraPreview(session: cameraViewModel.captureSession)
                .edgesIgnoringSafeArea(.all)
            VStack {
                HStack {
                    ForEach(persistantKeywodDetection.keys.sorted(), id: \.self) { keyword in
                        Image(systemName: imageFor(keyword))
                            .foregroundColor(binding(for: keyword).wrappedValue > 0 || liveBinding(for: keyword).wrappedValue ? .green : .red)
                            .font(.system(size: 25))
                            .opacity(0.7)
                    }
                }.onChange(of: speechRecognizer.transcript) { _, _ in
                    for keyword in persistantKeywodDetection.keys {
                        if (speechRecognizer.transcript.lowercased().contains(keyword)) {
                            liveKeywordDetection[keyword] = true
                        }
                    }
                }
                RoundedRectangle(cornerRadius: 20)
                    .frame(width: 100, height: 40)
                    .foregroundColor(.black)
                    .opacity(1)
                    .overlay(
                        HStack {
                            Image(systemName: "clock")
                                .foregroundColor(countdown > 10 ? .white : .red)
                            
                            Text("\(countdown)s")
                                .foregroundColor(countdown > 10 ? .white : .red)
                        }
                    )
                    .padding(.bottom, 20)
                Spacer()
                HStack {
                    Spacer()
                    Image(systemName: "record.circle")
                        .resizable()
                        .frame(width: 96, height: 96)
                        .foregroundColor(self.isRecording && self.didLongPress ? .red : .white)
                        .padding().scaleEffect(self.isRecording && self.didLongPress ? 1.2 : 1.0)
                        .onLongPressGesture(minimumDuration: 100, maximumDistance: 1000, perform: {
                        }) { state in
                            if (state) {
                                startRecording()
                            } else {
                                stopRecording()
                            }
                            
                        }
                    if (!self.isRecording) {
                        Button {
                            showAlert = true
                        } label: {
                            Image(systemName: "delete.left")
                                .resizable()
                                .frame(width: 28, height: 24)
                                .foregroundColor(videoIndex == -1 ? .gray : .red)
                                .padding()
                            
                        }.disabled(videoIndex == -1)
                        
                        NavigationLink {
                            PostReviewView(trackData: trackData, isPresented: $isPresented)
                        } label: {
                            Image(systemName: videoIndex == -1 && countdown > 30 ? "checkmark.circle" : "checkmark.circle.fill")
                                .resizable()
                                .frame(width: 32, height: 32)
                                .foregroundColor(videoIndex == -1 && countdown > 30 ? .gray : .green)
                                .padding()
                        }.disabled(videoIndex == -1 && countdown > 30)
                    } else {
                        Spacer().frame(width: 28, height: 24).padding()
                        Spacer().frame(width: 32, height: 32).padding()
                    }
                }
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Remove Last Recording"),
                message: Text("Are you sure you want to remove the previous recording?"),
                primaryButton: .default(Text("Cancel")),
                secondaryButton: .destructive(Text("Remove"), action: {
                    if let removedValue = trackData.removeValue(forKey: videoIndex) {
                        for keyword in persistantKeywodDetection.keys {
                            if let currentValue = persistantKeywodDetection[keyword]{
                                if currentValue > 0 {
                                    let calc = currentValue - removedValue.transcript.numberOfOccurrencesOf(string: keyword)
                                    persistantKeywodDetection[keyword] = currentValue - removedValue.transcript.numberOfOccurrencesOf(string: keyword)
                                    if calc <= 0 {
                                        liveKeywordDetection[keyword] = false
                                    }
                                }
                            }
                        }
                        countdown+=removedValue.duration
                        self.videoIndex-=1
                    }
                    showAlert = false
                })
            )
        }
        .onAppear {
            //TODO -- need to figure out how to call this everytime the page shows
            cameraViewModel.checkCameraAndAudioPermissions()
        }
        .onDisappear {
            print("CameraView onDisappear called...")
            cameraViewModel.releaseResources()
            speechRecognizer.stopTranscribing()
        }.navigationBarBackButtonHidden(self.isRecording && self.didLongPress)
    }
}


//struct CameraView_Previews: PreviewProvider {
//    static var previews: some View {
//        CameraView()
//    }
//}
