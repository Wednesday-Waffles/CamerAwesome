//
//  CameraPreview.h
//  camerawesome
//
//  Created by Dimitri Dessus on 23/07/2020.
//

#include <stdatomic.h>

#import <Flutter/Flutter.h>
#import <AVFoundation/AVFoundation.h>
#import <libkern/OSAtomic.h>
#import <Foundation/Foundation.h>

#import "MotionController.h"
#import "LocationController.h"
#import "VideoController.h"
#import "ImageStreamController.h"
#import "CameraSensor.h"
#import "CaptureModes.h"
#import "CameraFlash.h"
#import "CameraQualities.h"
#import "CameraPictureController.h"
#import "PermissionsController.h"
#import "AspectRatio.h"
#import "CameraSensorType.h"
#import "PhysicalButtonController.h"
#import "InputAnalysisImageFormat.h"
#import "CameraPreviewTexture.h"
#import "MultiCameraPreview.h"

NS_ASSUME_NONNULL_BEGIN

@interface SingleCameraPreview : NSObject<AVCaptureVideoDataOutputSampleBufferDelegate,
AVCaptureAudioDataOutputSampleBufferDelegate>

// TODO: move this to a single camera ?
@property(readonly, nonatomic) AVCaptureSession *captureSession;
@property(readonly, nonatomic) AVCaptureDevice *captureDevice;
@property(readonly, nonatomic) AVCaptureInput *captureVideoInput;
@property(readonly, nonatomic) AVCaptureConnection *captureConnection;
@property(readonly, nonatomic) AVCaptureVideoDataOutput *captureVideoOutput;
@property(readonly, nonatomic) AVCaptureVideoPreviewLayer *previewLayer;
@property(readonly, nonatomic) AVCapturePhotoOutput *capturePhotoOutput;

@property(readonly, nonatomic) UIDeviceOrientation deviceOrientation;
@property(readonly, nonatomic) AVCaptureFlashMode flashMode;
@property(readonly, nonatomic) AVCaptureTorchMode torchMode;
@property(readonly, nonatomic) AVCaptureAudioDataOutput *audioOutput;
@property(readonly, nonatomic) PigeonSensorPosition cameraSensorPosition;
@property(readonly, nonatomic) NSString *captureDeviceId;
@property(readonly, nonatomic) CaptureModes captureMode;
@property(readonly, nonatomic) NSString *currentPreset;
@property(readonly, nonatomic) AspectRatio aspectRatio;
@property(readonly, nonatomic) CupertinoVideoOptions *videoOptions;
@property(readonly, nonatomic) VideoRecordingQuality recordingQuality;
@property(readonly, nonatomic) CameraPreviewTexture* previewTexture;
@property(readonly, nonatomic) bool saveGPSLocation;
@property(readonly, nonatomic) bool mirrorFrontCamera;
@property(readonly, nonatomic) CGSize currentPreviewSize;
@property(readonly, nonatomic) ImageStreamController *imageStreamController;
@property(readonly, nonatomic) MotionController *motionController;
@property(readonly, nonatomic) LocationController *locationController;
@property(readonly, nonatomic) VideoController *videoController;
@property(readonly, nonatomic) PhysicalButtonController *physicalButtonController;
@property(readonly, copy) void (^completion)(NSNumber * _Nullable, FlutterError * _Nullable);
@property(nonatomic, copy) void (^onPreviewFrameAvailable)(void);
@property(nonatomic, copy) void (^onFirstFrameReceived)(void);

// Native audio debug injection properties (for testing only)
// Debug modes:
// 0 = none (normal behavior)
// 1 = preWarmFailsRetrySucceeds (first attempt fails, retry succeeds)
// 2 = preWarmFailsRetryFails (all attempts fail)
// 3 = preWarmDelayed (slow setup, simulates race condition)
// 4 = permissionDenied (simulate permission error)
@property(nonatomic) NSInteger nativeAudioDebugMode;
@property(nonatomic) NSInteger nativeAudioDebugDelayMs;
@property(nonatomic) NSInteger nativeAudioSetupAttemptCount;

- (instancetype)initWithCameraSensor:(PigeonSensorPosition)sensor
                        videoOptions:(nullable CupertinoVideoOptions *)videoOptions
                    recordingQuality:(VideoRecordingQuality)recordingQuality
                        streamImages:(BOOL)streamImages
                   mirrorFrontCamera:(BOOL)mirrorFrontCamera
                enablePhysicalButton:(BOOL)enablePhysicalButton
                     aspectRatioMode:(AspectRatio)aspectRatioMode
                         captureMode:(CaptureModes)captureMode
                          completion:(nonnull void (^)(NSNumber * _Nullable, FlutterError * _Nullable))completion
                       dispatchQueue:(dispatch_queue_t)dispatchQueue;
- (void)setImageStreamEvent:(FlutterEventSink)imageStreamEventSink;
- (void)setOrientationEventSink:(FlutterEventSink)orientationEventSink;
- (void)setPhysicalButtonEventSink:(FlutterEventSink)physicalButtonEventSink;
- (void)setAudioLevelEventSink:(FlutterEventSink)audioLevelEventSink;
- (void)setPreviewSize:(CGSize)previewSize error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error;
- (void)setFlashMode:(CameraFlashMode)flashMode error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error;
- (void)setCaptureMode:(CaptureModes)captureMode error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error;
- (void)setCameraPreset:(CGSize)currentPreviewSize;
- (void)setRecordingAudioMode:(bool)enableAudio completion:(void(^)(NSNumber *_Nullable, FlutterError *_Nullable))completion;
- (void)pauseVideoRecording;
- (void)resumeVideoRecording;
- (void)receivedImageFromStream;
- (void)setAspectRatio:(AspectRatio)ratio;
- (void)setExifPreferencesGPSLocation:(bool)gpsLocation completion:(void(^)(NSNumber *_Nullable, FlutterError *_Nullable))completion;
- (void)refresh;
- (void)start;
- (void)stop;
- (void)takePictureAtPath:(NSString *)path completion:(nonnull void (^)(NSNumber * _Nullable, FlutterError * _Nullable))completion;
- (void)recordVideoAtPath:(NSString *)path completion:(nonnull void (^)(FlutterError * _Nullable))completion;
- (void)stopRecordingVideo:(nonnull void (^)(NSNumber * _Nullable, FlutterError * _Nullable))completion;
- (void)focusOnPoint:(CGPoint)position preview:(CGSize)preview error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error;
- (void)dispose;
- (void)setSensor:(PigeonSensor *)sensor;
- (void)setZoom:(float)value error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error;
- (void)setMirrorFrontCamera:(bool)value error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error;
- (CGFloat)getMaxZoom;
- (CGSize)getEffectivPreviewSize;
- (void)setUpCaptureSessionForAudioError:(nonnull void (^)(NSError *))error;
- (void)setBrightness:(NSNumber *)brightness error:(FlutterError * _Nullable __autoreleasing * _Nonnull)error;

/// Ensures audio is ready for recording, retrying setup if pre-warm failed.
/// This is the async version with completion callback.
- (void)ensureAudioReadyWithCompletion:(nonnull void (^)(BOOL success, NSError * _Nullable error))completion;

/// Synchronous wrapper for ensureAudioReady. Returns YES if audio is ready.
- (BOOL)ensureAudioReadyWithError:(NSError * _Nullable * _Nullable)outError;

/// Sets native-level audio debug mode for testing.
/// This injects failures at the NATIVE layer to test ensureAudioReady() detection.
/// @param mode Debug mode (0=none, 1=preWarmFailsRetrySucceeds, 2=preWarmFailsRetryFails, 3=preWarmDelayed, 4=permissionDenied)
/// @param delayMs Delay in milliseconds for mode 3 (preWarmDelayed)
- (void)setNativeAudioDebugMode:(NSInteger)mode delayMs:(NSInteger)delayMs;

/// Returns YES if audio is currently set up and ready for recording.
/// This reflects the actual native state - useful for debugging and verification.
- (BOOL)isAudioSetup;
@end

NS_ASSUME_NONNULL_END
