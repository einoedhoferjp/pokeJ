import SwiftUI
import UIKit
import VisionKit

/// Kamera-Scanner auf Basis von `VNDocumentCameraViewController`.
///
/// Der Dokumentenscanner erkennt die Kartenkanten und führt bereits eine
/// Perspektivkorrektur durch.
struct DocumentScannerView: UIViewControllerRepresentable {
    let onComplete: (UIImage) -> Void
    let onCancel: () -> Void

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let controller = VNDocumentCameraViewController()
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onComplete: onComplete, onCancel: onCancel)
    }

    final class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        private let onComplete: (UIImage) -> Void
        private let onCancel: () -> Void

        init(onComplete: @escaping (UIImage) -> Void, onCancel: @escaping () -> Void) {
            self.onComplete = onComplete
            self.onCancel = onCancel
        }

        func documentCameraViewController(
            _ controller: VNDocumentCameraViewController,
            didFinishWith scan: VNDocumentCameraScan
        ) {
            if scan.pageCount > 0 {
                onComplete(scan.imageOfPage(at: 0))
            } else {
                onCancel()
            }
        }

        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            onCancel()
        }

        func documentCameraViewController(
            _ controller: VNDocumentCameraViewController,
            didFailWithError error: Error
        ) {
            onCancel()
        }
    }
}
