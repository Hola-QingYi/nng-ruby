# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
