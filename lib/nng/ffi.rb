# frozen_string_literal: true

require 'ffi'

module NNG
  # FFI bindings for libnng
  module FFI
    extend ::FFI::Library

    # Try to load libnng from various locations
    @lib_paths = [
      File.expand_path('../../ext/nng/libnng.so.1.8.0', __dir__),
      '/usr/local/lib/libnng.so',
      '/usr/lib/libnng.so',
      '/usr/lib/x86_64-linux-gnu/libnng.so'
    ]

    @loaded_lib_path = nil
    @lib_paths.each do |path|
      if File.exist?(path)
        begin
          ffi_lib path
          @loaded_lib_path = path
          break
        rescue LoadError
          next
        end
      end
    end

    raise LoadError, "Could not find libnng.so in any of: #{@lib_paths.join(', ')}" unless @loaded_lib_path

    def self.loaded_lib_path
      @loaded_lib_path
    end

    # ============================================================================
    # Constants
    # ============================================================================

    NNG_MAJOR_VERSION = 1
    NNG_MINOR_VERSION = 8
    NNG_PATCH_VERSION = 0

    # Maximum address length
    NNG_MAXADDRLEN = 128

    # Error codes
    NNG_OK           = 0
    NNG_EINTR        = 1
    NNG_ENOMEM       = 2
    NNG_EINVAL       = 3
    NNG_EBUSY        = 4
    NNG_ETIMEDOUT    = 5
    NNG_ECONNREFUSED = 6
    NNG_ECLOSED      = 7
    NNG_EAGAIN       = 8
    NNG_ENOTSUP      = 9
    NNG_EADDRINUSE   = 10
    NNG_ESTATE       = 11
    NNG_ENOENT       = 12
    NNG_EPROTO       = 13
    NNG_EUNREACHABLE = 14
    NNG_EADDRINVAL   = 15
    NNG_EPERM        = 16
    NNG_EMSGSIZE     = 17
    NNG_ECONNABORTED = 18
    NNG_ECONNRESET   = 19
    NNG_ECANCELED    = 20
    NNG_ENOFILES     = 21
    NNG_ENOSPC       = 22
    NNG_EEXIST       = 23
    NNG_EREADONLY    = 24
    NNG_EWRITEONLY   = 25
    NNG_ECRYPTO      = 26
    NNG_EPEERAUTH    = 27
    NNG_ENOARG       = 28
    NNG_EAMBIGUOUS   = 29
    NNG_EBADTYPE     = 30
    NNG_ECONNSHUT    = 31
    NNG_EINTERNAL    = 1000

    # Flags
    NNG_FLAG_ALLOC    = 1   # Allocate receive buffer
    NNG_FLAG_NONBLOCK = 2   # Non-blocking mode

    # Socket address families
    NNG_AF_UNSPEC   = 0
    NNG_AF_INPROC   = 1
    NNG_AF_IPC      = 2
    NNG_AF_INET     = 3
    NNG_AF_INET6    = 4
    NNG_AF_ZT       = 5
    NNG_AF_ABSTRACT = 6

    # Pipe events
    NNG_PIPE_EV_ADD_PRE  = 0
    NNG_PIPE_EV_ADD_POST = 1
    NNG_PIPE_EV_REM_POST = 2
    NNG_PIPE_EV_NUM      = 3

    # ============================================================================
    # Type definitions
    # ============================================================================

    # nng_socket structure
    class NngSocket < ::FFI::Struct
      layout :id, :uint32
    end

    # nng_dialer structure
    class NngDialer < ::FFI::Struct
      layout :id, :uint32
    end

    # nng_listener structure
    class NngListener < ::FFI::Struct
      layout :id, :uint32
    end

    # nng_ctx structure
    class NngCtx < ::FFI::Struct
      layout :id, :uint32
    end

    # nng_pipe structure
    class NngPipe < ::FFI::Struct
      layout :id, :uint32
    end

    # nng_duration - time interval in milliseconds
    typedef :int32, :nng_duration

    # nng_time - absolute time in milliseconds
    typedef :uint64, :nng_time

    # Opaque types
    typedef :pointer, :nng_msg
    typedef :pointer, :nng_aio
    typedef :pointer, :nng_stat

    # Socket address structures
    class NngSockaddrInproc < ::FFI::Struct
      layout :sa_family, :uint16,
             :sa_name, [:char, NNG_MAXADDRLEN]
    end

    class NngSockaddrPath < ::FFI::Struct
      layout :sa_family, :uint16,
             :sa_path, [:char, NNG_MAXADDRLEN]
    end

    class NngSockaddrIn < ::FFI::Struct
      layout :sa_family, :uint16,
             :sa_port, :uint16,
             :sa_addr, :uint32
    end

    class NngSockaddrIn6 < ::FFI::Struct
      layout :sa_family, :uint16,
             :sa_port, :uint16,
             :sa_addr, [:uint8, 16],
             :sa_scope, :uint32
    end

    class NngSockaddrStorage < ::FFI::Struct
      layout :sa_family, :uint16,
             :sa_pad, [:uint64, 16]
    end

    class NngSockaddr < ::FFI::Union
      layout :s_family, :uint16,
             :s_inproc, NngSockaddrInproc,
             :s_ipc, NngSockaddrPath,
             :s_in, NngSockaddrIn,
             :s_in6, NngSockaddrIn6,
             :s_storage, NngSockaddrStorage
    end

    # ============================================================================
    # Core functions
    # ============================================================================

    # Library finalization
    attach_function :nng_fini, [], :void

    # Error handling
    attach_function :nng_strerror, [:int], :string

    # Socket functions
    attach_function :nng_close, [NngSocket.by_value], :int
    attach_function :nng_socket_id, [NngSocket.by_value], :int

    # Socket options - set
    attach_function :nng_setopt, [NngSocket.by_value, :string, :pointer, :size_t], :int
    attach_function :nng_setopt_bool, [NngSocket.by_value, :string, :bool], :int
    attach_function :nng_setopt_int, [NngSocket.by_value, :string, :int], :int
    attach_function :nng_setopt_size, [NngSocket.by_value, :string, :size_t], :int
    attach_function :nng_setopt_uint64, [NngSocket.by_value, :string, :uint64], :int
    attach_function :nng_setopt_string, [NngSocket.by_value, :string, :string], :int
    attach_function :nng_setopt_ptr, [NngSocket.by_value, :string, :pointer], :int
    attach_function :nng_setopt_ms, [NngSocket.by_value, :string, :nng_duration], :int

    # Socket options - get
    attach_function :nng_getopt, [NngSocket.by_value, :string, :pointer, :pointer], :int
    attach_function :nng_getopt_bool, [NngSocket.by_value, :string, :pointer], :int
    attach_function :nng_getopt_int, [NngSocket.by_value, :string, :pointer], :int
    attach_function :nng_getopt_size, [NngSocket.by_value, :string, :pointer], :int
    attach_function :nng_getopt_uint64, [NngSocket.by_value, :string, :pointer], :int
    attach_function :nng_getopt_string, [NngSocket.by_value, :string, :pointer], :int
    attach_function :nng_getopt_ptr, [NngSocket.by_value, :string, :pointer], :int
    attach_function :nng_getopt_ms, [NngSocket.by_value, :string, :pointer], :int

    # Connection management
    attach_function :nng_listen, [NngSocket.by_value, :string, :pointer, :int], :int
    attach_function :nng_dial, [NngSocket.by_value, :string, :pointer, :int], :int

    # Dialer functions
    attach_function :nng_dialer_create, [:pointer, NngSocket.by_value, :string], :int
    attach_function :nng_dialer_start, [NngDialer.by_value, :int], :int
    attach_function :nng_dialer_close, [NngDialer.by_value], :int
    attach_function :nng_dialer_id, [NngDialer.by_value], :int

    # Listener functions
    attach_function :nng_listener_create, [:pointer, NngSocket.by_value, :string], :int
    attach_function :nng_listener_start, [NngListener.by_value, :int], :int
    attach_function :nng_listener_close, [NngListener.by_value], :int
    attach_function :nng_listener_id, [NngListener.by_value], :int

    # Send and receive (synchronous)
    attach_function :nng_send, [NngSocket.by_value, :pointer, :size_t, :int], :int
    attach_function :nng_recv, [NngSocket.by_value, :pointer, :pointer, :int], :int

    # Message-based send/receive
    attach_function :nng_sendmsg, [NngSocket.by_value, :nng_msg, :int], :int
    attach_function :nng_recvmsg, [NngSocket.by_value, :pointer, :int], :int

    # Memory management
    attach_function :nng_free, [:pointer, :size_t], :void
    attach_function :nng_strfree, [:pointer], :void

    # Message functions
    attach_function :nng_msg_alloc, [:pointer, :size_t], :int
    attach_function :nng_msg_free, [:nng_msg], :void
    attach_function :nng_msg_realloc, [:nng_msg, :size_t], :int
    attach_function :nng_msg_header, [:nng_msg], :pointer
    attach_function :nng_msg_header_len, [:nng_msg], :size_t
    attach_function :nng_msg_body, [:nng_msg], :pointer
    attach_function :nng_msg_len, [:nng_msg], :size_t
    attach_function :nng_msg_append, [:nng_msg, :pointer, :size_t], :int
    attach_function :nng_msg_insert, [:nng_msg, :pointer, :size_t], :int
    attach_function :nng_msg_trim, [:nng_msg, :size_t], :int
    attach_function :nng_msg_chop, [:nng_msg, :size_t], :int
    attach_function :nng_msg_header_append, [:nng_msg, :pointer, :size_t], :int
    attach_function :nng_msg_header_insert, [:nng_msg, :pointer, :size_t], :int
    attach_function :nng_msg_header_trim, [:nng_msg, :size_t], :int
    attach_function :nng_msg_header_chop, [:nng_msg, :size_t], :int
    attach_function :nng_msg_clear, [:nng_msg], :void
    attach_function :nng_msg_header_clear, [:nng_msg], :void
    attach_function :nng_msg_dup, [:pointer, :nng_msg], :int
    attach_function :nng_msg_get_pipe, [:nng_msg], NngPipe.by_value
    attach_function :nng_msg_set_pipe, [:nng_msg, NngPipe.by_value], :void

    # Context functions
    attach_function :nng_ctx_open, [:pointer, NngSocket.by_value], :int
    attach_function :nng_ctx_close, [NngCtx.by_value], :int
    attach_function :nng_ctx_id, [NngCtx.by_value], :int
    attach_function :nng_ctx_send, [NngCtx.by_value, :nng_aio], :void
    attach_function :nng_ctx_recv, [NngCtx.by_value, :nng_aio], :void
    attach_function :nng_ctx_sendmsg, [NngCtx.by_value, :nng_msg, :int], :int
    attach_function :nng_ctx_recvmsg, [NngCtx.by_value, :pointer, :int], :int

    # Pipe functions
    attach_function :nng_pipe_id, [NngPipe.by_value], :int
    attach_function :nng_pipe_socket, [NngPipe.by_value], NngSocket.by_value
    attach_function :nng_pipe_dialer, [NngPipe.by_value], NngDialer.by_value
    attach_function :nng_pipe_listener, [NngPipe.by_value], NngListener.by_value
    attach_function :nng_pipe_close, [NngPipe.by_value], :int

    # Asynchronous I/O functions
    attach_function :nng_aio_alloc, [:pointer, :pointer, :pointer], :int
    attach_function :nng_aio_free, [:nng_aio], :void
    attach_function :nng_aio_stop, [:nng_aio], :void
    attach_function :nng_aio_result, [:nng_aio], :int
    attach_function :nng_aio_count, [:nng_aio], :size_t
    attach_function :nng_aio_cancel, [:nng_aio], :void
    attach_function :nng_aio_abort, [:nng_aio, :int], :void
    attach_function :nng_aio_wait, [:nng_aio], :void
    attach_function :nng_aio_set_msg, [:nng_aio, :nng_msg], :void
    attach_function :nng_aio_get_msg, [:nng_aio], :nng_msg
    attach_function :nng_aio_set_input, [:nng_aio, :uint, :pointer], :int
    attach_function :nng_aio_set_output, [:nng_aio, :uint, :pointer], :int
    attach_function :nng_aio_set_timeout, [:nng_aio, :nng_duration], :void
    attach_function :nng_aio_set_iov, [:nng_aio, :uint, :pointer], :int
    attach_function :nng_aio_begin, [:nng_aio], :bool
    attach_function :nng_aio_finish, [:nng_aio, :int], :void
    attach_function :nng_aio_defer, [:nng_aio, :pointer, :pointer], :void

    # Asynchronous send/receive
    attach_function :nng_send_aio, [NngSocket.by_value, :nng_aio], :void
    attach_function :nng_recv_aio, [NngSocket.by_value, :nng_aio], :void

    # Statistics functions
    attach_function :nng_stats_get, [:pointer], :int
    attach_function :nng_stats_free, [:nng_stat], :void
    attach_function :nng_stats_dump, [:nng_stat], :void
    attach_function :nng_stat_next, [:nng_stat], :nng_stat
    attach_function :nng_stat_child, [:nng_stat], :nng_stat
    attach_function :nng_stat_name, [:nng_stat], :string
    attach_function :nng_stat_type, [:nng_stat], :int
    attach_function :nng_stat_unit, [:nng_stat], :int
    attach_function :nng_stat_value, [:nng_stat], :uint64
    attach_function :nng_stat_desc, [:nng_stat], :string

    # Device functions (forwarder/reflector)
    attach_function :nng_device, [NngSocket.by_value, NngSocket.by_value], :int

    # Utility functions
    attach_function :nng_sleep_aio, [:nng_duration, :nng_aio], :void
    attach_function :nng_msleep, [:nng_duration], :void

    # URL parsing
    typedef :pointer, :nng_url
    attach_function :nng_url_parse, [:pointer, :string], :int
    attach_function :nng_url_free, [:nng_url], :void
    attach_function :nng_url_clone, [:pointer, :nng_url], :int

    # ============================================================================
    # Protocol-specific functions (will be attached when protocol is loaded)
    # ============================================================================

    # These will be attached by specific protocol modules:
    # - nng_pair0_open, nng_pair1_open
    # - nng_push0_open, nng_pull0_open
    # - nng_pub0_open, nng_sub0_open
    # - nng_req0_open, nng_rep0_open
    # - nng_surveyor0_open, nng_respondent0_open
    # - nng_bus0_open

    # ============================================================================
    # Helper methods
    # ============================================================================

    # Check error code and raise exception if not OK
    def self.check_error(ret, operation = "NNG operation")
      return if ret == NNG_OK
      error_msg = nng_strerror(ret)
      raise NNG::Error, "#{operation} failed: #{error_msg} (code: #{ret})"
    end

    # Create initialized socket
    def self.socket_initializer
      NngSocket.new.tap { |s| s[:id] = 0 }
    end

    # Create initialized dialer
    def self.dialer_initializer
      NngDialer.new.tap { |d| d[:id] = 0 }
    end

    # Create initialized listener
    def self.listener_initializer
      NngListener.new.tap { |l| l[:id] = 0 }
    end

    # Create initialized context
    def self.ctx_initializer
      NngCtx.new.tap { |c| c[:id] = 0 }
    end

    # Create initialized pipe
    def self.pipe_initializer
      NngPipe.new.tap { |p| p[:id] = 0 }
    end
  end
end
