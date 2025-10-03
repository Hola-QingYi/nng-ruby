#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'nng/version'
require_relative 'nng/ffi'
require_relative 'nng/socket'
require_relative 'nng/message'
require_relative 'nng/errors'

# NNG (nanomsg-next-generation) Ruby bindings
#
# @example Basic usage
#   require 'nng'
#
#   # Create a pair socket
#   socket = NNG::Socket.new(:pair1)
#   socket.listen("tcp://127.0.0.1:5555")
#
#   # Send a message
#   socket.send("Hello, NNG!")
#
#   # Receive a message
#   data = socket.recv
#   puts data
#
#   # Close the socket
#   socket.close
#
module NNG
  class Error < StandardError; end

  # NNG library version
  # @return [String] version string
  def self.version
    VERSION
  end

  # NNG library version (from C library)
  # @return [String] version string from libnng
  def self.lib_version
    "#{FFI::NNG_MAJOR_VERSION}.#{FFI::NNG_MINOR_VERSION}.#{FFI::NNG_PATCH_VERSION}"
  end

  # Cleanup NNG library (optional, called automatically at exit)
  def self.fini
    FFI.nng_fini
  end

  at_exit do
    fini
  end
end
