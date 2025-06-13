## 1.2.0

- **Improved example clarity**: Enhanced the example to make it easier to understand
- **Fixed RGB calculation issue**: Resolved a bug causing RGB calculation failures on iOS
- **Pinned camera_avfoundation dependency**: Locked camera_avfoundation to version 0.9.18+14 due to [reported issue](https://github.com/flutter/flutter/issues/170240#issuecomment-2967164077)

## 1.1.0

- **Enhanced camera control**: `isFlashOn` and `isFocusAndExposureLocked` setters now directly control camera hardware when camera controller is available
- **Added comprehensive test suite**: Added unit tests to verify camera controller interactions and setter behaviors
- **Better error handling**: Camera control setters safely handle null camera controller scenarios

## 1.0.1

- Updated dependencies to latest versions
- Shortened package description in pubspec.yaml

## 1.0.0

- Initial version.
