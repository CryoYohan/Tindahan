import SwiftUI
import AVFoundation
import Vision

// 1. The UIKit Controller that manages the hardware camera
class ScannerViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    var captureSession: AVCaptureSession?
    var onBarcodeScanned: ((String) -> Void)?
    var isScanning = true

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
    }

    private func setupCamera() {
        captureSession = AVCaptureSession()
        guard let session = captureSession else { return }

        guard let videoDevice = AVCaptureDevice.default(for: .video),
              let videoInput = try? AVCaptureDeviceInput(device: videoDevice) else { return }

        if session.canAddInput(videoInput) { session.addInput(videoInput) }

        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        if session.canAddOutput(videoOutput) { session.addOutput(videoOutput) }

        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)

        DispatchQueue.global(qos: .background).async {
            session.startRunning()
        }
    }

    // 2. The Vision Framework intercepts every frame to look for barcodes
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard isScanning, let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let request = VNDetectBarcodesRequest { [weak self] request, _ in
            guard let results = request.results as? [VNBarcodeObservation],
                  let barcode = results.first?.payloadStringValue else { return }

            // Instantly pause scanning so it doesn't trigger 60 times a second
            self?.isScanning = false

            DispatchQueue.main.async {
                self?.onBarcodeScanned?(barcode)
            }
        }

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        try? handler.perform([request])
    }
    
    func resumeScanning() {
        isScanning = true
    }
}

// 3. The SwiftUI Wrapper
struct BarcodeScannerView: UIViewControllerRepresentable {
    var onScanned: (String) -> Void
    @Binding var isScanning: Bool

    func makeUIViewController(context: Context) -> ScannerViewController {
        let controller = ScannerViewController()
        controller.onBarcodeScanned = { barcode in
            onScanned(barcode)
        }
        return controller
    }

    func updateUIViewController(_ uiViewController: ScannerViewController, context: Context) {
        if isScanning {
            uiViewController.resumeScanning()
        }
    }
}
