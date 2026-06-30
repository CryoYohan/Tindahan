import SwiftUI
import VisionKit
import Vision

struct ReceiptScannerView: UIViewControllerRepresentable {
    @Binding var recognizedText: String
    @Environment(\.dismiss) var dismiss

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let documentCameraViewController = VNDocumentCameraViewController()
        documentCameraViewController.delegate = context.coordinator
        return documentCameraViewController
    }

    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(recognizedText: $recognizedText, dismiss: dismiss)
    }

    class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        @Binding var recognizedText: String
        var dismiss: DismissAction

        init(recognizedText: Binding<String>, dismiss: DismissAction) {
            self._recognizedText = recognizedText
            self.dismiss = dismiss
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            var extractedText = ""
            
            // A DispatchGroup ensures we wait for all pages to finish processing
            let group = DispatchGroup()

            for pageIndex in 0..<scan.pageCount {
                let image = scan.imageOfPage(at: pageIndex)
                guard let cgImage = image.cgImage else { continue }

                group.enter()
                
                // Set up the Vision request to find text
                let request = VNRecognizeTextRequest { (request, error) in
                    guard let observations = request.results as? [VNRecognizedTextObservation] else {
                        group.leave()
                        return
                    }
                    
                    // Extract the top candidate string from each line of text
                    let pageText = observations.compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n")
                    extractedText += pageText + "\n"
                    
                    group.leave()
                }
                
                // Force the engine to prioritize accuracy over speed
                request.recognitionLevel = .accurate

                // Execute the request
                let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
                try? handler.perform([request])
            }

            // Once all pages are processed, update the UI on the main thread
            group.notify(queue: .main) {
                self.recognizedText = extractedText
                self.dismiss()
            }
        }

        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            dismiss()
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            dismiss()
        }
    }
}
