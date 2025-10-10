# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.1] - 2025-10-10

### Fixed
- Include bundled library files (nng.dll, libnng.so.1.11.0) in gem package
- Gem now works out-of-the-box on Windows and Linux without manual configuration

## [1.0.0] - 2025-10-10

### Added
- Windows platform support with bundled nng.dll
- macOS platform support (ready for libnng.dylib)
- Dynamic library version detection via `nng_version()` API
- Automatic platform detection and library path resolution
- Windows test suite (test_windows.rb, test_windows_full.rb)

### Changed
- **BREAKING**: Upgraded bundled NNG library from v1.8.0 to v1.11.0
- Refactored library loading logic for cross-platform compatibility
- Updated `NNG.lib_version` to use runtime version detection
- Library search paths now platform-aware (.dll/.dylib/.so)
- Updated all documentation to reflect v1.11.0 and cross-platform support

### Infrastructure
- Cross-platform support (Windows/macOS/Linux)
- Platform-specific bundled libraries
- Enhanced error messages with platform-specific guidance

## [0.1.2] - 2025-10-10

### Added
- Protocol Buffers integration documentation
- Enhanced README with detailed usage examples

## [0.1.1] - 2025-10-03

### Changed
- Published to GitHub repository
- Updated gem packaging to include source code

## [0.1.0] - 2025-10-03

### Added
- Initial release of NNG Ruby bindings
- Complete FFI bindings for NNG 1.8.0 (libnng 1.9.0)
- Support for all scalability protocols:
  - Pair (pair0, pair1)
  - Push/Pull (push0, pull0)
  - Pub/Sub (pub0, sub0)
  - Req/Rep (req0, rep0)
  - Surveyor/Respondent (surveyor0, respondent0)
  - Bus (bus0)
- Support for all transports:
  - TCP
  - IPC
  - Inproc
  - WebSocket
  - TLS
- High-level Ruby API with automatic resource management
- Message-based communication (NNG::Message)
- Socket options and configuration
- Comprehensive error handling
- Bundled libnng shared library (no external dependencies)
- Full async I/O support
- Complete documentation and examples
- RSpec test suite

### Infrastructure
- Gem packaging with bundled shared library
- CI/CD ready structure
- YARD documentation support
- Example programs for all protocols
