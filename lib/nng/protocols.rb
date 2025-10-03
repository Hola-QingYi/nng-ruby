# frozen_string_literal: true

module NNG
  # Protocol-specific socket opening functions
  module Protocols
    # Dynamically load protocol functions from libnng
    def self.attach_protocol_functions
      extend ::FFI::Library

      # Use the same library as FFI module
      ffi_lib NNG::FFI.loaded_lib_path

      # Pair protocols
      attach_function :nng_pair0_open, [FFI::NngSocket.by_ref], :int
      attach_function :nng_pair0_open_raw, [FFI::NngSocket.by_ref], :int
      attach_function :nng_pair1_open, [FFI::NngSocket.by_ref], :int
      attach_function :nng_pair1_open_raw, [FFI::NngSocket.by_ref], :int
      attach_function :nng_pair1_open_poly, [FFI::NngSocket.by_ref], :int

      # Push/Pull protocols
      attach_function :nng_push0_open, [FFI::NngSocket.by_ref], :int
      attach_function :nng_push0_open_raw, [FFI::NngSocket.by_ref], :int
      attach_function :nng_pull0_open, [FFI::NngSocket.by_ref], :int
      attach_function :nng_pull0_open_raw, [FFI::NngSocket.by_ref], :int

      # Pub/Sub protocols
      attach_function :nng_pub0_open, [FFI::NngSocket.by_ref], :int
      attach_function :nng_pub0_open_raw, [FFI::NngSocket.by_ref], :int
      attach_function :nng_sub0_open, [FFI::NngSocket.by_ref], :int
      attach_function :nng_sub0_open_raw, [FFI::NngSocket.by_ref], :int

      # Req/Rep protocols
      attach_function :nng_req0_open, [FFI::NngSocket.by_ref], :int
      attach_function :nng_req0_open_raw, [FFI::NngSocket.by_ref], :int
      attach_function :nng_rep0_open, [FFI::NngSocket.by_ref], :int
      attach_function :nng_rep0_open_raw, [FFI::NngSocket.by_ref], :int

      # Surveyor/Respondent protocols
      attach_function :nng_surveyor0_open, [FFI::NngSocket.by_ref], :int
      attach_function :nng_surveyor0_open_raw, [FFI::NngSocket.by_ref], :int
      attach_function :nng_respondent0_open, [FFI::NngSocket.by_ref], :int
      attach_function :nng_respondent0_open_raw, [FFI::NngSocket.by_ref], :int

      # Bus protocol
      attach_function :nng_bus0_open, [FFI::NngSocket.by_ref], :int
      attach_function :nng_bus0_open_raw, [FFI::NngSocket.by_ref], :int
    rescue ::FFI::NotFoundError => e
      # Some protocols might not be available in all builds
      warn "Warning: Some NNG protocol functions not available: #{e.message}"
    end

    # Protocol name to function mapping
    PROTOCOL_FUNCTIONS = {
      pair0: :nng_pair0_open,
      pair1: :nng_pair1_open,
      pair: :nng_pair1_open, # alias for pair1
      push0: :nng_push0_open,
      push: :nng_push0_open,
      pull0: :nng_pull0_open,
      pull: :nng_pull0_open,
      pub0: :nng_pub0_open,
      pub: :nng_pub0_open,
      sub0: :nng_sub0_open,
      sub: :nng_sub0_open,
      req0: :nng_req0_open,
      req: :nng_req0_open,
      rep0: :nng_rep0_open,
      rep: :nng_rep0_open,
      surveyor0: :nng_surveyor0_open,
      surveyor: :nng_surveyor0_open,
      respondent0: :nng_respondent0_open,
      respondent: :nng_respondent0_open,
      bus0: :nng_bus0_open,
      bus: :nng_bus0_open
    }.freeze

    # Open a socket for the given protocol
    # @param protocol [Symbol] protocol name (:pair0, :pair1, :push, :pull, etc.)
    # @param raw [Boolean] open in raw mode
    # @return [FFI::NngSocket] opened socket
    def self.open_socket(protocol, raw: false)
      func_name = PROTOCOL_FUNCTIONS[protocol]
      raise ArgumentError, "Unknown protocol: #{protocol}" unless func_name

      func_name = "#{func_name}_raw".to_sym if raw

      socket = FFI.socket_initializer
      ret = send(func_name, socket)
      FFI.check_error(ret, "Opening #{protocol} socket")
      socket
    end
  end
end

# Auto-load protocol functions
NNG::Protocols.attach_protocol_functions
