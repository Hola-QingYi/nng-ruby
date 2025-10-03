# NNG Ruby Bindings

[![Gem Version](https://badge.fury.io/rb/nng-ruby.svg)](https://badge.fury.io/rb/nng-ruby)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Ruby bindings for [NNG (nanomsg-next-generation)](https://nng.nanomsg.org/), a lightweight messaging library.

## Features

- ✅ Complete FFI bindings for NNG 1.8.0 (300+ functions)
- ✅ All scalability protocols: Pair, Push/Pull, Pub/Sub, Req/Rep, Surveyor/Respondent, Bus
- ✅ All transports: TCP, IPC, Inproc, WebSocket, TLS
- ✅ High-level Ruby API with automatic resource management
- ✅ Message-based and byte-based communication
- ✅ Bundled libnng.so.1.8.0 shared library (no external dependencies)
- ✅ Thread-safe
- ✅ Full async I/O support
- ✅ Automated testing and publishing via GitHub Actions

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'nng-ruby'
```

And then execute:

```bash
bundle install
```

Or install it yourself as:

```bash
gem install nng-ruby
```

## Quick Start

### Pair Protocol (Bidirectional)

```ruby
require 'nng'

# Server
server = NNG::Socket.new(:pair1)
server.listen("tcp://127.0.0.1:5555")

# Client
client = NNG::Socket.new(:pair1)
client.dial("tcp://127.0.0.1:5555")

# Send and receive
client.send("Hello, NNG!")
puts server.recv  # => "Hello, NNG!"

server.send("Hello back!")
puts client.recv  # => "Hello back!"

# Cleanup
server.close
client.close
```

### Request/Reply Protocol

```ruby
require 'nng'

# Server (replier)
rep = NNG::Socket.new(:rep)
rep.listen("tcp://127.0.0.1:5556")

# Client (requester)
req = NNG::Socket.new(:req)
req.dial("tcp://127.0.0.1:5556")

# Send request and get reply
req.send("What is the answer?")
puts rep.recv  # => "What is the answer?"

rep.send("42")
puts req.recv  # => "42"

rep.close
req.close
```

### Publish/Subscribe Protocol

```ruby
require 'nng'

# Publisher
pub = NNG::Socket.new(:pub)
pub.listen("tcp://127.0.0.1:5557")

# Subscriber
sub = NNG::Socket.new(:sub)
sub.dial("tcp://127.0.0.1:5557")
sub.set_option("sub:subscribe", "") # Subscribe to all topics

# Publish messages
pub.send("Hello, subscribers!")
puts sub.recv  # => "Hello, subscribers!"

pub.close
sub.close
```

### Push/Pull Protocol (Pipeline)

```ruby
require 'nng'

# Producer
push = NNG::Socket.new(:push)
push.listen("tcp://127.0.0.1:5558")

# Consumer
pull = NNG::Socket.new(:pull)
pull.dial("tcp://127.0.0.1:5558")

# Send work
push.send("Task 1")
puts pull.recv  # => "Task 1"

push.close
pull.close
```

## Supported Protocols

- **Pair** - Bidirectional 1:1 communication (`pair0`, `pair1`)
- **Push/Pull** - Unidirectional pipeline (`push0`, `pull0`)
- **Pub/Sub** - One-to-many distribution (`pub0`, `sub0`)
- **Req/Rep** - Request/reply pattern (`req0`, `rep0`)
- **Surveyor/Respondent** - Survey pattern (`surveyor0`, `respondent0`)
- **Bus** - Many-to-many (`bus0`)

## Supported Transports

- **TCP** - `tcp://host:port`
- **IPC** - `ipc:///path/to/socket`
- **Inproc** - `inproc://name`
- **WebSocket** - `ws://host:port/path`
- **TLS** - `tls+tcp://host:port`

## Advanced Usage

### Custom Library Configuration

By default, nng-ruby uses the bundled libnng.so.1.8.0 library. However, you can specify a custom NNG library in several ways:

#### Option 1: At install time

Use gem install options to specify a custom NNG library location:

```bash
# Specify NNG installation directory (will search lib/, lib64/, etc.)
gem install nng-ruby -- --with-nng-dir=/opt/nng

# Specify exact library path
gem install nng-ruby -- --with-nng-lib=/opt/nng/lib/libnng.so

# Specify include directory (for future use)
gem install nng-ruby -- --with-nng-include=/opt/nng/include
```

#### Option 2: At runtime with environment variables

Set environment variables before requiring the gem:

```bash
# Specify exact library file path
export NNG_LIB_PATH=/usr/local/lib/libnng.so.1.9.0
ruby your_script.rb

# Or specify library directory (will search for libnng.so*)
export NNG_LIB_DIR=/usr/local/lib
ruby your_script.rb
```

In Ruby code:

```ruby
# Set before requiring nng
ENV['NNG_LIB_PATH'] = '/custom/path/libnng.so'
require 'nng'

# Or use directory
ENV['NNG_LIB_DIR'] = '/custom/path/lib'
require 'nng'
```

#### Priority Order

The library is loaded in this priority order:

1. **Environment variable** `NNG_LIB_PATH` (highest priority)
2. **Environment variable** `NNG_LIB_DIR`
3. **Install-time configuration** (gem install --with-nng-*)
4. **Bundled library** (ext/nng/libnng.so.1.8.0)
5. **System paths** (/usr/local/lib, /usr/lib, etc.)

#### Debugging

Enable debug output to see which library is being loaded:

```bash
export NNG_DEBUG=1
ruby your_script.rb
```

This will print messages showing:
- Which paths are being searched
- Which library was successfully loaded
- Any load failures encountered

### Setting Timeouts

```ruby
socket = NNG::Socket.new(:pair1)
socket.send_timeout = 5000  # 5 seconds
socket.recv_timeout = 5000  # 5 seconds
```

### Non-blocking I/O

```ruby
require 'nng'

socket = NNG::Socket.new(:pair1)
socket.listen("tcp://127.0.0.1:5555")

begin
  data = socket.recv(flags: NNG::FFI::NNG_FLAG_NONBLOCK)
  puts "Received: #{data}"
rescue NNG::Error => e
  puts "No data available: #{e.message}"
end
```

### Using Messages

```ruby
require 'nng'

# Create a message
msg = NNG::Message.new
msg.append("Hello, ")
msg.append("World!")
puts msg.body  # => "Hello, World!"

# Add header
msg.header_append("Type: Greeting")

# Duplicate message
msg2 = msg.dup

# Free message
msg.free
msg2.free
```

### Socket Options

```ruby
socket = NNG::Socket.new(:pub)

# Set options
socket.set_option("send-buffer", 8192)
socket.set_option("tcp-nodelay", true)
socket.set_option_ms("send-timeout", 1000)

# Get options
buffer_size = socket.get_option("send-buffer", type: :int)
nodelay = socket.get_option("tcp-nodelay", type: :bool)
```

## Examples

See the `examples/` directory for complete working examples:

- `examples/pair.rb` - Pair protocol
- `examples/reqrep.rb` - Request/Reply protocol
- `examples/pubsub.rb` - Publish/Subscribe protocol

Run examples:

```bash
ruby examples/pair.rb
ruby examples/reqrep.rb
ruby examples/pubsub.rb
```

## API Documentation

### NNG Module

- `NNG.version` - Gem version
- `NNG.lib_version` - NNG library version
- `NNG.fini` - Cleanup NNG (called automatically)

### NNG::Socket

#### Creating Sockets

```ruby
socket = NNG::Socket.new(:pair1)
socket = NNG::Socket.new(:req, raw: false)
```

#### Connection Methods

- `listen(url, flags: 0)` - Listen on address
- `dial(url, flags: 0)` - Connect to address
- `close` - Close socket
- `closed?` - Check if closed

#### Send/Receive Methods

- `send(data, flags: 0)` - Send data
- `recv(flags: NNG::FFI::NNG_FLAG_ALLOC)` - Receive data

#### Option Methods

- `set_option(name, value)` - Set socket option
- `get_option(name, type: :int)` - Get socket option
- `set_option_ms(name, ms)` - Set timeout option
- `send_timeout=(ms)` - Set send timeout
- `recv_timeout=(ms)` - Set receive timeout

#### Information Methods

- `id` - Get socket ID

### NNG::Message

#### Creating Messages

```ruby
msg = NNG::Message.new(size: 0)
```

#### Body Methods

- `append(data)` - Append to body
- `insert(data)` - Insert at beginning
- `body` - Get body content
- `length` / `size` - Get body length
- `clear` - Clear body

#### Header Methods

- `header_append(data)` - Append to header
- `header` - Get header content
- `header_length` - Get header length
- `header_clear` - Clear header

#### Other Methods

- `dup` - Duplicate message
- `free` - Free message
- `freed?` - Check if freed

### Error Handling

```ruby
begin
  socket.send("data")
rescue NNG::TimeoutError => e
  puts "Timeout: #{e.message}"
rescue NNG::ConnectionRefused => e
  puts "Connection refused: #{e.message}"
rescue NNG::Error => e
  puts "NNG error: #{e.message}"
end
```

Available error classes:
- `NNG::Error` - Base error
- `NNG::TimeoutError`
- `NNG::ConnectionRefused`
- `NNG::ConnectionAborted`
- `NNG::ConnectionReset`
- `NNG::Closed`
- `NNG::AddressInUse`
- `NNG::NoMemory`
- `NNG::MessageSize`
- `NNG::ProtocolError`
- `NNG::StateError`

## Requirements

- Ruby 2.5 or later
- FFI gem

The NNG shared library (libnng.so.1.8.0) is bundled with the gem, so no external installation is required.

## Development

```bash
# Clone repository
git clone https://github.com/Hola-QingYi/nng-ruby.git
cd nng-ruby

# Install dependencies
bundle install

# Run tests
bundle exec rspec

# Build gem
gem build nng.gemspec

# Run examples
ruby examples/pair.rb
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## License

MIT License - see LICENSE file for details.

## Credits

- NNG library: https://nng.nanomsg.org/
- Original nanomsg: https://nanomsg.org/

## Links

- [NNG Documentation](https://nng.nanomsg.org/man/)
- [GitHub Repository](https://github.com/Hola-QingYi/nng-ruby)
- [RubyGems Page](https://rubygems.org/gems/nng-ruby)

## Version History

### 0.1.1 (2025-10-03)
- Published to GitHub repository
- Updated gem packaging to include source code
- Added GitHub Actions workflows for CI/CD

### 0.1.0 (2025-10-03)
- Initial release
- Complete NNG 1.8.0 API bindings
- All protocols and transports supported
- Bundled libnng.so.1.8.0
- High-level Ruby API
- Message support
- Examples and documentation
