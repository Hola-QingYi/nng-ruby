# frozen_string_literal: true

module NNG
  # Base error class for all NNG errors
  class Error < StandardError; end

  # Connection errors
  class ConnectionError < Error; end
  class ConnectionRefused < ConnectionError; end
  class ConnectionAborted < ConnectionError; end
  class ConnectionReset < ConnectionError; end

  # Timeout error
  class TimeoutError < Error; end

  # Resource errors
  class ResourceError < Error; end
  class AddressInUse < ResourceError; end
  class NoMemory < ResourceError; end

  # Protocol errors
  class ProtocolError < Error; end
  class MessageSize < ProtocolError; end

  # State errors
  class StateError < Error; end
  class Closed < StateError; end

  # Map error codes to exception classes
  ERROR_MAP = {
    FFI::NNG_ETIMEDOUT    => TimeoutError,
    FFI::NNG_ECONNREFUSED => ConnectionRefused,
    FFI::NNG_ECONNABORTED => ConnectionAborted,
    FFI::NNG_ECONNRESET   => ConnectionReset,
    FFI::NNG_ECLOSED      => Closed,
    FFI::NNG_EADDRINUSE   => AddressInUse,
    FFI::NNG_ENOMEM       => NoMemory,
    FFI::NNG_EMSGSIZE     => MessageSize,
    FFI::NNG_EPROTO       => ProtocolError,
    FFI::NNG_ESTATE       => StateError
  }.freeze

  # Raise appropriate exception for error code
  def self.raise_error(code, message)
    error_class = ERROR_MAP[code] || Error
    raise error_class, message
  end
end
