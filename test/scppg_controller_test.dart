import 'package:flutter_test/flutter_test.dart';
import 'package:scppg/src/scppg_controller.dart';
import 'package:camera/camera.dart';
import 'package:mocktail/mocktail.dart';

// Mock classes for camera and permission handler
class MockCameraDescription extends Mock {
  int get sensorOrientation => 0;
  CameraLensDirection get lensDirection => CameraLensDirection.back;
  String get name => "Mock Camera";
}

// Additional mock class needed for the tests
class MockCameraController extends Mock implements CameraController {}

void main() {
  // Register fallback values for enum types used in mocks
  setUpAll(() {
    registerFallbackValue(FlashMode.off);
    registerFallbackValue(FocusMode.auto);
    registerFallbackValue(ExposureMode.auto);
  });

  late ScppgController scppgController;

  setUp(() {
    scppgController = ScppgController(fps: 30);
  });

  group('ScppgController initialization', () {
    test('Initial state should be properly set', () {
      // Check initial properties
      expect(scppgController.fps, 30);
      expect(scppgController.redRatioThreshold, 30);
      expect(scppgController.isSensing, false);
      expect(scppgController.isFocusAndExposureLocked, false);
      expect(scppgController.isFlashOn, false);
      expect(scppgController.now, isNull);
      expect(scppgController.ppgData, isNull);
    });

    test(
      'Setting redRatioThreshold should update value and notify listeners',
      () {
        bool listenerCalled = false;
        scppgController.addListener(() {
          listenerCalled = true;
        });

        scppgController.redRatioThreshold = 50;

        expect(scppgController.redRatioThreshold, 50);
        expect(listenerCalled, true);
      },
    );

    test(
      'Setting isFocusAndExposureLocked should update value and notify listeners',
      () {
        bool listenerCalled = false;
        scppgController.addListener(() {
          listenerCalled = true;
        });

        scppgController.isFocusAndExposureLocked = true;

        expect(scppgController.isFocusAndExposureLocked, true);
        expect(listenerCalled, true);
      },
    );

    test('Setting isFlashOn should update value and notify listeners', () {
      bool listenerCalled = false;
      scppgController.addListener(() {
        listenerCalled = true;
      });

      scppgController.isFlashOn = true;

      expect(scppgController.isFlashOn, true);
      expect(listenerCalled, true);
    });
  });

  group('SCPPGData class', () {
    test('SCPPGData should properly initialize with given values', () {
      final now = DateTime.now();
      final data = SCPPGData(r: 100.0, g: 50.0, b: 25.0, timestamp: now);

      expect(data.r, 100.0);
      expect(data.g, 50.0);
      expect(data.b, 25.0);
      expect(data.timestamp, now);
    });

    test('SCPPGData should handle null values', () {
      final data = SCPPGData();

      expect(data.r, isNull);
      expect(data.g, isNull);
      expect(data.b, isNull);
      expect(data.timestamp, isNull);
    });
  });

  group('Camera and sensing operations', () {
    // This test requires integration with the camera plugin, which is difficult to test in pure unit tests
    // In a real implementation, you would use a more sophisticated mocking approach
    test('stopSensing should reset state correctly', () {
      // Manually set the state that would normally be set during startSensing
      scppgController.isFlashOn = true;
      scppgController.isFocusAndExposureLocked = true;

      // Reset all state values
      scppgController.stopSensing();

      // Verify reset state
      expect(scppgController.isSensing, false);
      expect(scppgController.isFlashOn, false);
      expect(scppgController.isFocusAndExposureLocked, false);
    });
  });

  group('Advanced camera mocking tests', () {
    // Note: These tests are more complex and would need proper mocking of the camera plugin
    // The following is just a conceptual example of what you might test

    test('RGB calculation with proper values should create valid SCPPGData', () {
      // In a full implementation, you would setup a mock camera that returns specific frame values
      // and then verify that _scanImage processes them correctly to produce the expected RGB values
      // This is just a placeholder for how that would be structured

      // For example, testing with fake RGB values:
      final data = SCPPGData(
        r: 120.0,
        g: 80.0,
        b: 40.0,
        timestamp: DateTime.now(),
      );
      expect(data.r, 120.0);
      expect(data.g, 80.0);
      expect(data.b, 40.0);
      expect(data.timestamp, isNotNull);
    });
  });

  group('Camera controller interaction tests', () {
    late MockCameraController mockCameraController;

    setUp(() {
      mockCameraController = MockCameraController();
    });

    test(
      'isFlashOn setter should call setFlashMode when camera controller exists',
      () {
        // Arrange: Set up the mock camera controller
        scppgController.cameraController = mockCameraController;
        when(
          () => mockCameraController.setFlashMode(any()),
        ).thenAnswer((_) async {});

        // Act: Set flash on
        scppgController.isFlashOn = true;

        // Assert: Verify the camera controller method was called
        verify(
          () => mockCameraController.setFlashMode(FlashMode.torch),
        ).called(1);
        expect(scppgController.isFlashOn, true);
      },
    );

    test(
      'isFlashOn setter should call setFlashMode with off when set to false',
      () {
        // Arrange
        scppgController.cameraController = mockCameraController;
        when(
          () => mockCameraController.setFlashMode(any()),
        ).thenAnswer((_) async {});

        // Act
        scppgController.isFlashOn = false;

        // Assert
        verify(
          () => mockCameraController.setFlashMode(FlashMode.off),
        ).called(1);
        expect(scppgController.isFlashOn, false);
      },
    );

    test(
      'isFlashOn setter should not crash when camera controller is null',
      () {
        // Arrange: Ensure camera controller is null
        scppgController.cameraController = null;

        // Act & Assert: Should not throw
        expect(() => scppgController.isFlashOn = true, returnsNormally);
        expect(scppgController.isFlashOn, true);
      },
    );

    test(
      'isFocusAndExposureLocked setter should call focus and exposure methods when true',
      () {
        // Arrange
        scppgController.cameraController = mockCameraController;
        when(
          () => mockCameraController.setFocusMode(any()),
        ).thenAnswer((_) async {});
        when(
          () => mockCameraController.setExposureMode(any()),
        ).thenAnswer((_) async {});

        // Act
        scppgController.isFocusAndExposureLocked = true;

        // Assert
        verify(
          () => mockCameraController.setFocusMode(FocusMode.locked),
        ).called(1);
        verify(
          () => mockCameraController.setExposureMode(ExposureMode.locked),
        ).called(1);
        expect(scppgController.isFocusAndExposureLocked, true);
      },
    );

    test(
      'isFocusAndExposureLocked setter should call focus and exposure methods when false',
      () {
        // Arrange
        scppgController.cameraController = mockCameraController;
        when(
          () => mockCameraController.setFocusMode(any()),
        ).thenAnswer((_) async {});
        when(
          () => mockCameraController.setExposureMode(any()),
        ).thenAnswer((_) async {});

        // Act
        scppgController.isFocusAndExposureLocked = false;

        // Assert
        verify(
          () => mockCameraController.setFocusMode(FocusMode.auto),
        ).called(1);
        verify(
          () => mockCameraController.setExposureMode(ExposureMode.auto),
        ).called(1);
        expect(scppgController.isFocusAndExposureLocked, false);
      },
    );

    test(
      'isFocusAndExposureLocked setter should not crash when camera controller is null',
      () {
        // Arrange: Ensure camera controller is null
        scppgController.cameraController = null;

        // Act & Assert: Should not throw
        expect(
          () => scppgController.isFocusAndExposureLocked = true,
          returnsNormally,
        );
        expect(scppgController.isFocusAndExposureLocked, true);
      },
    );

    test('Both setters should notify listeners', () {
      // Arrange
      scppgController.cameraController = mockCameraController;
      when(
        () => mockCameraController.setFlashMode(any()),
      ).thenAnswer((_) async {});
      when(
        () => mockCameraController.setFocusMode(any()),
      ).thenAnswer((_) async {});
      when(
        () => mockCameraController.setExposureMode(any()),
      ).thenAnswer((_) async {});

      int listenerCallCount = 0;
      scppgController.addListener(() {
        listenerCallCount++;
      });

      // Act
      scppgController.isFlashOn = true;
      scppgController.isFocusAndExposureLocked = true;

      // Assert
      expect(listenerCallCount, 2);
    });
  });
}
