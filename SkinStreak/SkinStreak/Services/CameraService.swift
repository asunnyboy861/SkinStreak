import AVFoundation
import Combine
import SwiftUI
import UIKit

@MainActor
final class CameraController: NSObject, ObservableObject {
    @Published var meanLuma: Double = 0
    @Published var lightStatus: LightGuardStatus = .ok
    @Published var isRunning = false

    let session = AVCaptureSession()
    var baselineLuma: Double?
    var onPhotoCaptured: ((Data) -> Void)?

    private let photoOutput = AVCapturePhotoOutput()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let sessionQueue = DispatchQueue(label: "skinstreak.camera.session")
    private var configured = false

    func configureAndStart() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            if !self.configured {
                self.configureIfNeeded()
                self.configured = true
            }
            if !self.session.isRunning {
                self.session.startRunning()
            }
            Task { @MainActor in self.isRunning = self.session.isRunning }
        }
    }

    func stop() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            if self.session.isRunning {
                self.session.stopRunning()
            }
            Task { @MainActor in self.isRunning = false }
        }
    }

    func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    private func configureIfNeeded() {
        guard session.inputs.isEmpty else { return }
        session.beginConfiguration()
        session.sessionPreset = .photo
        if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
            ?? AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
            if let input = try? AVCaptureDeviceInput(device: device), session.canAddInput(input) {
                session.addInput(input)
            }
        }
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
        }
        videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange
        ]
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "skinstreak.camera.frames"))
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
        }
        if let connection = videoOutput.connection(with: .video), connection.isVideoOrientationSupported {
            connection.videoOrientation = .portrait
        }
        session.commitConfiguration()
    }
}

extension CameraController: AVCapturePhotoCaptureDelegate, AVCaptureVideoDataOutputSampleBufferDelegate {
    nonisolated func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let luma = LightGuard.meanLuma(from: pixelBuffer)
        Task { @MainActor in
            self.meanLuma = luma
            self.lightStatus = LightGuard.evaluate(meanLuma: luma, baseline: self.baselineLuma)
        }
    }

    nonisolated func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard error == nil, let data = photo.fileDataRepresentation(), !data.isEmpty else { return }
        Task { @MainActor in
            self.onPhotoCaptured?(data)
        }
    }
}

@MainActor
final class BarcodeScannerController: NSObject, ObservableObject {
    @Published var detectedCode: String?
    @Published var isRunning = false

    let session = AVCaptureSession()
    private let metadataOutput = AVCaptureMetadataOutput()
    private let sessionQueue = DispatchQueue(label: "skinstreak.scanner.session")
    private var configured = false

    func configureAndStart() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            if !self.configured {
                self.configureIfNeeded()
                self.configured = true
            }
            if !self.session.isRunning {
                self.session.startRunning()
            }
            Task { @MainActor in self.isRunning = self.session.isRunning }
        }
    }

    func stop() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            if self.session.isRunning {
                self.session.stopRunning()
            }
            Task { @MainActor in self.isRunning = false }
        }
    }

    private func configureIfNeeded() {
        guard session.inputs.isEmpty else { return }
        session.beginConfiguration()
        session.sessionPreset = .hd1920x1080
        if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
           let input = try? AVCaptureDeviceInput(device: device), session.canAddInput(input) {
            session.addInput(input)
        }
        if session.canAddOutput(metadataOutput) {
            session.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue(label: "skinstreak.scanner.codes"))
            let types: [AVMetadataObject.ObjectType] = [.ean8, .ean13, .upce, .code39, .code93, .code128, .qr, .interleaved2of5]
            metadataOutput.metadataObjectTypes = types.filter(metadataOutput.availableMetadataObjectTypes.contains)
        }
        session.commitConfiguration()
    }
}

extension BarcodeScannerController: AVCaptureMetadataOutputObjectsDelegate {
    nonisolated func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard let code = metadataObjects.compactMap({ $0 as? AVMetadataMachineReadableCodeObject }).first,
              let value = code.stringValue, !value.isEmpty else { return }
        Task { @MainActor in
            if self.detectedCode == nil {
                self.detectedCode = value
            }
        }
    }
}

struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession

    final class PreviewView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
    }

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        view.backgroundColor = .black
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {}
}
