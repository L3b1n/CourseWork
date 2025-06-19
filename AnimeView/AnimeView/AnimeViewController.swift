import AVFoundation
import SceneKit
import UIKit

#if canImport(AnimeViewMP)
    import AnimeViewMP
#endif

class AnimeViewController: UIViewController,
                           AVCaptureVideoDataOutputSampleBufferDelegate,
                           VideoProcessingDelegate
{
    let camera = Camera() // Use the updated Camera class with switching logic
    let displayLayer: AVSampleBufferDisplayLayer = .init()
    let videoProcessor: VideoProcessor = VideoProcessor()!

    private lazy var cameraView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var containView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.clipsToBounds = true
        return view
    }()

    private lazy var imgView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()
    
    // Switch Camera Button
    private lazy var switchCameraButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Switch Camera", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        button.layer.cornerRadius = 10
        button.addTarget(self, action: #selector(didTapSwitchCamera), for: .touchUpInside)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(imgView)
        view.addSubview(switchCameraButton)

        NSLayoutConstraint.activate([
            imgView.topAnchor.constraint(equalTo: view.topAnchor),
            imgView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            imgView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            imgView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            // Switch Camera Button Constraints
            switchCameraButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            switchCameraButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            switchCameraButton.widthAnchor.constraint(equalToConstant: 150),
            switchCameraButton.heightAnchor.constraint(equalToConstant: 50),
        ])

        camera.setSampleBufferDelegate(self)
        camera.start()
        videoProcessor.startGraph()
        videoProcessor.delegate = self
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        displayLayer.frame = cameraView.bounds
    }
    
    @objc private func didTapSwitchCamera() {
        camera.switchCamera() // Call the switch camera function
    }
    
    func captureOutput(
        _ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        connection.videoOrientation = .portrait
        displayLayer.enqueue(sampleBuffer)
        let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        videoProcessor.processVideoFrame(pixelBuffer)
    }

    func didProcessFrame(_ outputBuffer: CVPixelBuffer) {
        DispatchQueue.main.async {
            let ciImage = CIImage(cvPixelBuffer: outputBuffer)
            let uiImage = UIImage(ciImage: ciImage)
            self.imgView.contentMode = .scaleAspectFill
            self.imgView.image = uiImage
        }
    }
}
