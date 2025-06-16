import ARKit
import AVFoundation

class Camera: NSObject {
    enum CameraPosition {
        case front
        case back
    }
    
    private(set) var currentPosition: CameraPosition = .front

    lazy var session: AVCaptureSession = .init()
    private var device: AVCaptureDevice?
    private var input: AVCaptureDeviceInput?
    lazy var output: AVCaptureVideoDataOutput = .init()
    
    override init() {
        super.init()
        configureSession(for: currentPosition)
    }
    
    /// Configures the session with the specified camera position
    private func configureSession(for position: CameraPosition) {
        session.beginConfiguration()
        defer { session.commitConfiguration() }
        
        // Remove existing input if any
        if let existingInput = input {
            session.removeInput(existingInput)
        }
        
        // Set up new camera device
        let newPosition: AVCaptureDevice.Position = position == .front ? .front : .back
        if let newDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: newPosition),
           let newInput = try? AVCaptureDeviceInput(device: newDevice) {
            
            self.device = newDevice
            self.input = newInput
            
            if session.canAddInput(newInput) {
                session.addInput(newInput)
            }
        }
        
        // Ensure output is configured
        if session.outputs.isEmpty {
            output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
            if session.canAddOutput(output) {
                session.addOutput(output)
            }
        }
    }
    
    /// Switches the camera between front and back
    func switchCamera() {
        currentPosition = (currentPosition == .front) ? .back : .front
        configureSession(for: currentPosition)
    }
    
    func setSampleBufferDelegate(_ delegate: AVCaptureVideoDataOutputSampleBufferDelegate) {
        output.setSampleBufferDelegate(delegate, queue: .main)
    }

    func start() {
        if !session.isRunning {
            session.startRunning()
        }
    }

    func stop() {
        if session.isRunning {
            session.stopRunning()
        }
    }
}
