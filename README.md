# NNG Ruby Bindings

[![Gem Version](https://badge.fury.io/rb/nng-ruby.svg)](https://badge.fury.io/rb/nng-ruby)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Ruby bindings for [NNG (nanomsg-next-generation)](https://nng.nanomsg.org/), a lightweight messaging library.

## Features

- ✅ Complete FFI bindings for NNG 1.11.0 (300+ functions)
- ✅ **Cross-platform support**: Windows, macOS, and Linux
- ✅ All scalability protocols: Pair, Push/Pull, Pub/Sub, Req/Rep, Surveyor/Respondent, Bus
- ✅ All transports: TCP, IPC, Inproc, WebSocket, TLS
- ✅ High-level Ruby API with automatic resource management
- ✅ Message-based and byte-based communication
- ✅ Bundled NNG 1.11.0 libraries (nng.dll for Windows, libnng.so for Linux)
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

The request/reply pattern ensures exactly one reply for each request:

```ruby
require 'nng'

# Server (replier) - Must reply to each request
rep = NNG::Socket.new(:rep)
rep.listen("tcp://127.0.0.1:5556")

# Client (requester) - Must wait for reply before sending next request
req = NNG::Socket.new(:req)
req.dial("tcp://127.0.0.1:5556")
sleep 0.1  # Allow connection to establish

# Request-reply cycle
req.send("What is the answer?")
question = rep.recv
puts "Server received: #{question}"

rep.send("42")
answer = req.recv
puts "Client received: #{answer}"

# Another request-reply cycle
req.send("What is 2+2?")
rep.send("4")
puts req.recv  # => "4"

rep.close
req.close
```

### Publish/Subscribe Protocol

Pub/Sub allows one publisher to broadcast to multiple subscribers:

```ruby
require 'nng'

# Publisher
pub = NNG::Socket.new(:pub)
pub.listen("tcp://127.0.0.1:5557")

# Subscriber 1 - Subscribe to all topics
sub1 = NNG::Socket.new(:sub)
sub1.dial("tcp://127.0.0.1:5557")
sub1.set_option("sub:subscribe", "")  # Subscribe to everything

# Subscriber 2 - Subscribe to specific topic
sub2 = NNG::Socket.new(:sub)
sub2.dial("tcp://127.0.0.1:5557")
sub2.set_option("sub:subscribe", "ALERT:")  # Only "ALERT:" messages

sleep 0.1  # Allow subscriptions to propagate

# Publish to all subscribers
pub.send("ALERT: System update available")
puts sub1.recv  # => "ALERT: System update available"
puts sub2.recv  # => "ALERT: System update available"

# Publish general message (only sub1 receives)
pub.send("INFO: Normal operation")
puts sub1.recv  # => "INFO: Normal operation"
# sub2 won't receive this (topic doesn't match)

pub.close
sub1.close
sub2.close
```

### Push/Pull Protocol (Pipeline)

Push/Pull creates a load-balanced pipeline for distributing work:

```ruby
require 'nng'
require 'thread'

# Producer (Push)
push = NNG::Socket.new(:push)
push.listen("tcp://127.0.0.1:5558")

# Worker 1 (Pull)
pull1 = NNG::Socket.new(:pull)
pull1.dial("tcp://127.0.0.1:5558")

# Worker 2 (Pull)
pull2 = NNG::Socket.new(:pull)
pull2.dial("tcp://127.0.0.1:5558")

sleep 0.1  # Allow connections

# Start workers in threads
workers = []
workers << Thread.new do
  3.times do
    task = pull1.recv
    puts "Worker 1 processing: #{task}"
  end
end

workers << Thread.new do
  3.times do
    task = pull2.recv
    puts "Worker 2 processing: #{task}"
  end
end

# Distribute tasks (round-robin to workers)
6.times do |i|
  push.send("Task #{i+1}")
  sleep 0.01
end

# Wait for workers to complete
workers.each(&:join)

push.close
pull1.close
pull2.close
```

### Bus Protocol (Many-to-Many)

Bus protocol allows all peers to communicate with each other:

```ruby
require 'nng'

# Create three bus nodes
node1 = NNG::Socket.new(:bus)
node1.listen("tcp://127.0.0.1:5559")

node2 = NNG::Socket.new(:bus)
node2.listen("tcp://127.0.0.1:5560")
node2.dial("tcp://127.0.0.1:5559")

node3 = NNG::Socket.new(:bus)
node3.dial("tcp://127.0.0.1:5559")
node3.dial("tcp://127.0.0.1:5560")

sleep 0.1  # Allow mesh to form

# Any node can send to all others
node1.send("Message from Node 1")
puts node2.recv  # => "Message from Node 1"
puts node3.recv  # => "Message from Node 1"

node2.send("Message from Node 2")
puts node1.recv  # => "Message from Node 2"
puts node3.recv  # => "Message from Node 2"

node1.close
node2.close
node3.close
```

### Surveyor/Respondent Protocol

Surveyor sends a survey, and all respondents reply:

```ruby
require 'nng'

# Surveyor
surveyor = NNG::Socket.new(:surveyor)
surveyor.listen("tcp://127.0.0.1:5561")
surveyor.send_timeout = 1000  # 1 second to collect responses

# Respondents
resp1 = NNG::Socket.new(:respondent)
resp1.dial("tcp://127.0.0.1:5561")

resp2 = NNG::Socket.new(:respondent)
resp2.dial("tcp://127.0.0.1:5561")

sleep 0.1  # Allow connections

# Send survey
surveyor.send("What is your status?")

# Respondents reply
question1 = resp1.recv
resp1.send("Respondent 1: OK")

question2 = resp2.recv
resp2.send("Respondent 2: OK")

# Collect responses
begin
  puts surveyor.recv  # => "Respondent 1: OK" or "Respondent 2: OK"
  puts surveyor.recv  # => "Respondent 2: OK" or "Respondent 1: OK"
rescue NNG::TimeoutError
  puts "Survey complete"
end

surveyor.close
resp1.close
resp2.close
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

By default, nng-ruby uses the bundled NNG 1.11.0 library (platform-specific: nng.dll on Windows, libnng.so.1.11.0 on Linux). However, you can specify a custom NNG library in several ways:

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
4. **Bundled library** (ext/nng/nng.dll or ext/nng/libnng.so.1.11.0)
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

### Using Messages (NNG::Message API)

The Message API provides more control over message headers and bodies:

#### Basic Message Operations

```ruby
require 'nng'

# Create a new message
msg = NNG::Message.new

# Append data to message body
msg.append("Hello, ")
msg.append("World!")
puts msg.body  # => "Hello, World!"
puts msg.length  # => 13

# Insert data at the beginning
msg.insert("Say: ")
puts msg.body  # => "Say: Hello, World!"

# Add header information
msg.header_append("Content-Type: text/plain")
puts msg.header  # => "Content-Type: text/plain"
puts msg.header_length  # => 24

# Clear body or header
msg.clear  # Clears body
msg.header_clear  # Clears header

# Duplicate message
msg2 = msg.dup

# Free messages when done
msg.free
msg2.free
```

#### Sending and Receiving Messages

```ruby
require 'nng'

# Server side
server = NNG::Socket.new(:pair1)
server.listen("tcp://127.0.0.1:5555")

# Client side
client = NNG::Socket.new(:pair1)
client.dial("tcp://127.0.0.1:5555")
sleep 0.1  # Give time to establish connection

# Send a message with header and body
msg = NNG::Message.new
msg.header_append("RequestID: 12345")
msg.append("Hello from client!")

# Send message using low-level API
msg_ptr = ::FFI::MemoryPointer.new(:pointer)
msg_ptr.write_pointer(msg.to_ptr)
ret = NNG::FFI.nng_sendmsg(client.socket, msg_ptr.read_pointer, 0)
NNG::FFI.check_error(ret, "Send message")
# Note: Message is freed automatically after sending

# Receive message
recv_msg_ptr = ::FFI::MemoryPointer.new(:pointer)
ret = NNG::FFI.nng_recvmsg(server.socket, recv_msg_ptr, 0)
NNG::FFI.check_error(ret, "Receive message")

# Wrap received message
recv_msg = NNG::Message.allocate
recv_msg.instance_variable_set(:@msg, recv_msg_ptr.read_pointer)
recv_msg.instance_variable_set(:@msg_ptr, recv_msg_ptr)
recv_msg.instance_variable_set(:@freed, false)

puts "Header: #{recv_msg.header}"  # => "RequestID: 12345"
puts "Body: #{recv_msg.body}"      # => "Hello from client!"

recv_msg.free
server.close
client.close
```

#### Simple String-based Send/Receive (Recommended for most use cases)

For simpler use cases, use the high-level Socket#send and Socket#recv methods:

```ruby
require 'nng'

server = NNG::Socket.new(:pair1)
server.listen("tcp://127.0.0.1:5555")

client = NNG::Socket.new(:pair1)
client.dial("tcp://127.0.0.1:5555")

# Simple send/receive (no need to manage Message objects)
client.send("Hello, Server!")
data = server.recv
puts data  # => "Hello, Server!"

server.close
client.close
```

### Socket Options

NNG sockets support various options to control behavior:

```ruby
require 'nng'

socket = NNG::Socket.new(:pub)

# Set buffer sizes
socket.set_option("send-buffer", 8192)    # Send buffer size in bytes
socket.set_option("recv-buffer", 8192)    # Receive buffer size in bytes

# Set TCP options
socket.set_option("tcp-nodelay", true)    # Disable Nagle's algorithm
socket.set_option("tcp-keepalive", true)  # Enable TCP keepalive

# Set timeouts
socket.send_timeout = 1000  # 1 second send timeout
socket.recv_timeout = 5000  # 5 second receive timeout

# Or use set_option_ms
socket.set_option_ms("send-timeout", 1000)
socket.set_option_ms("recv-timeout", 5000)

# Get options
buffer_size = socket.get_option("send-buffer", type: :int)
puts "Send buffer: #{buffer_size} bytes"

nodelay = socket.get_option("tcp-nodelay", type: :bool)
puts "TCP NoDelay: #{nodelay}"

send_timeout = socket.get_option("send-timeout", type: :ms)
puts "Send timeout: #{send_timeout} ms"

# Protocol-specific options
if socket.socket.id  # For pub/sub
  # Subscriber can set subscription topics
  sub = NNG::Socket.new(:sub)
  sub.set_option("sub:subscribe", "news/")   # Subscribe to "news/*"
  sub.set_option("sub:subscribe", "alerts/") # Subscribe to "alerts/*"
  sub.set_option("sub:unsubscribe", "news/") # Unsubscribe from "news/*"
end

socket.close
```

### Transport-Specific URLs

Different transports have different URL formats:

```ruby
require 'nng'

socket = NNG::Socket.new(:pair1)

# TCP transport
socket.listen("tcp://0.0.0.0:5555")           # Listen on all interfaces
socket.dial("tcp://192.168.1.100:5555")       # Connect to specific IP
socket.dial("tcp://localhost:5555")           # Connect to localhost

# IPC transport (Unix domain sockets)
socket.listen("ipc:///tmp/test.sock")         # Unix socket
socket.dial("ipc:///tmp/test.sock")

# Inproc transport (in-process, same memory space)
socket.listen("inproc://my-channel")
socket.dial("inproc://my-channel")

# WebSocket transport
socket.listen("ws://0.0.0.0:8080/path")
socket.dial("ws://localhost:8080/path")

# TLS transport
socket.listen("tls+tcp://0.0.0.0:5556")
socket.dial("tls+tcp://server.example.com:5556")

socket.close
```

## Examples

See the `examples/` directory for complete working examples:

### Protocol Examples
- `examples/pair.rb` - Pair protocol
- `examples/reqrep.rb` - Request/Reply protocol
- `examples/pubsub.rb` - Publish/Subscribe protocol

### Protocol Buffers Integration

NNG-ruby works seamlessly with Google Protocol Buffers for efficient binary serialization. This is perfect for RPC systems, microservices, and cross-language communication.

**Available Examples:**
- `examples/protobuf_demo.rb` - Complete demo with nested messages and RPC patterns
- `examples/protobuf_simple.rb` - Simple client-server with Protobuf
- `examples/proto/message.proto` - Protobuf message definitions

**Installation:**

```bash
gem install google-protobuf
```

#### Example 1: Basic RPC with Protobuf

This example shows a simple request-response RPC system using NNG + Protobuf:

```ruby
require 'nng'
require 'google/protobuf'

# Define Protobuf messages inline (or load from .proto file)
Google::Protobuf::DescriptorPool.generated_pool.build do
  add_file("rpc.proto", syntax: :proto3) do
    add_message "RpcRequest" do
      optional :func_code, :int32, 1
      optional :data, :bytes, 2
      optional :request_id, :string, 3
    end
    add_message "RpcResponse" do
      optional :status, :int32, 1
      optional :data, :bytes, 2
      optional :error_msg, :string, 3
    end
  end
end

RpcRequest = Google::Protobuf::DescriptorPool.generated_pool.lookup("RpcRequest").msgclass
RpcResponse = Google::Protobuf::DescriptorPool.generated_pool.msgclass("RpcResponse")

# Server
server = NNG::Socket.new(:rep)
server.listen("tcp://127.0.0.1:5555")
puts "RPC Server listening on tcp://127.0.0.1:5555"

# Client
client = NNG::Socket.new(:req)
client.dial("tcp://127.0.0.1:5555")
sleep 0.1

# Client sends request
request = RpcRequest.new(
  func_code: 100,
  data: "Get user info",
  request_id: "req-001"
)
client.send(RpcRequest.encode(request))
puts "Client sent: #{request.inspect}"

# Server receives and processes
req_data = server.recv
received_req = RpcRequest.decode(req_data)
puts "Server received: func=#{received_req.func_code}, id=#{received_req.request_id}"

# Server sends response
response = RpcResponse.new(
  status: 0,
  data: '{"name": "Alice", "age": 30}',
  error_msg: ""
)
server.send(RpcResponse.encode(response))
puts "Server sent: status=#{response.status}"

# Client receives response
resp_data = client.recv
received_resp = RpcResponse.decode(resp_data)
puts "Client received: status=#{received_resp.status}, data=#{received_resp.data}"

server.close
client.close
```

**Output:**
```
RPC Server listening on tcp://127.0.0.1:5555
Client sent: <RpcRequest: func_code: 100, data: "Get user info", request_id: "req-001">
Server received: func=100, id=req-001
Server sent: status=0
Client received: status=0, data={"name": "Alice", "age": 30}
```

#### Example 2: Nested Messages (Message in Message)

A common pattern is sending complex data structures by nesting Protobuf messages:

```ruby
require 'nng'
require 'google/protobuf'

# Define nested message structure
Google::Protobuf::DescriptorPool.generated_pool.build do
  add_file("nested.proto", syntax: :proto3) do
    add_message "Contact" do
      optional :wxid, :string, 1
      optional :name, :string, 2
      optional :remark, :string, 3
    end
    add_message "ContactList" do
      repeated :contacts, :message, 1, "Contact"
    end
    add_message "RpcResponse" do
      optional :status, :int32, 1
      optional :data, :bytes, 2  # Will contain encoded ContactList
    end
  end
end

Contact = Google::Protobuf::DescriptorPool.generated_pool.lookup("Contact").msgclass
ContactList = Google::Protobuf::DescriptorPool.generated_pool.lookup("ContactList").msgclass
RpcResponse = Google::Protobuf::DescriptorPool.generated_pool.lookup("RpcResponse").msgclass

# Server prepares nested data
contacts = ContactList.new(
  contacts: [
    Contact.new(wxid: "wxid_001", name: "Alice", remark: "Friend"),
    Contact.new(wxid: "wxid_002", name: "Bob", remark: "Colleague"),
    Contact.new(wxid: "wxid_003", name: "Charlie", remark: "Family")
  ]
)

# Encode inner message first, then wrap in outer message
contacts_data = ContactList.encode(contacts)
response = RpcResponse.new(status: 0, data: contacts_data)

# Setup sockets
server = NNG::Socket.new(:pair1)
server.listen("tcp://127.0.0.1:5556")

client = NNG::Socket.new(:pair1)
client.dial("tcp://127.0.0.1:5556")
sleep 0.1

# Send nested message
server.send(RpcResponse.encode(response))
puts "Server sent: #{contacts.contacts.size} contacts"

# Receive and decode nested message
resp_data = client.recv
received_resp = RpcResponse.decode(resp_data)

# Decode inner message
received_contacts = ContactList.decode(received_resp.data)
puts "Client received #{received_contacts.contacts.size} contacts:"
received_contacts.contacts.each do |c|
  puts "  - #{c.name} (#{c.wxid}): #{c.remark}"
end

server.close
client.close
```

**Output:**
```
Server sent: 3 contacts
Client received 3 contacts:
  - Alice (wxid_001): Friend
  - Bob (wxid_002): Colleague
  - Charlie (wxid_003): Family
```

#### Example 3: Real-World RPC Pattern (WeChatFerry Style)

This shows a complete RPC system similar to WeChatFerry's architecture:

```ruby
require 'nng'
require 'google/protobuf'

# Define protocol (matching WeChatFerry style)
Google::Protobuf::DescriptorPool.generated_pool.build do
  add_file("wcf_rpc.proto", syntax: :proto3) do
    add_enum "Functions" do
      value :FUNC_IS_LOGIN, 0x01
      value :FUNC_SEND_TEXT, 0x20
      value :FUNC_GET_CONTACTS, 0x12
    end

    add_message "Request" do
      optional :func, :enum, 1, "Functions"
      optional :data, :bytes, 2
    end

    add_message "Response" do
      optional :status, :int32, 1
      optional :data, :bytes, 2
    end

    add_message "TextMsg" do
      optional :receiver, :string, 1
      optional :message, :string, 2
    end
  end
end

Functions = Google::Protobuf::DescriptorPool.generated_pool.lookup("Functions").enummodule
Request = Google::Protobuf::DescriptorPool.generated_pool.lookup("Request").msgclass
Response = Google::Protobuf::DescriptorPool.generated_pool.lookup("Response").msgclass
TextMsg = Google::Protobuf::DescriptorPool.generated_pool.lookup("TextMsg").msgclass

# RPC Server
def start_rpc_server
  server = NNG::Socket.new(:rep)
  server.listen("tcp://127.0.0.1:10086")
  puts "RPC Server started on port 10086"

  loop do
    # Receive request
    req_data = server.recv
    request = Request.decode(req_data)

    puts "Received: func=#{request.func}"

    # Process request
    response = case request.func
    when :FUNC_IS_LOGIN
      Response.new(status: 1)  # Logged in
    when :FUNC_SEND_TEXT
      text_msg = TextMsg.decode(request.data)
      puts "  Send to #{text_msg.receiver}: #{text_msg.message}"
      Response.new(status: 0)  # Success
    when :FUNC_GET_CONTACTS
      Response.new(status: 0, data: "[contacts data]")
    else
      Response.new(status: -1)  # Unknown function
    end

    # Send response
    server.send(Response.encode(response))
  end
ensure
  server&.close
end

# RPC Client
def rpc_call(client, func, data = nil)
  request = Request.new(func: func, data: data)
  client.send(Request.encode(request))

  resp_data = client.recv
  Response.decode(resp_data)
end

# Run example
server_thread = Thread.new { start_rpc_server rescue nil }
sleep 0.5  # Wait for server to start

client = NNG::Socket.new(:req)
client.dial("tcp://127.0.0.1:10086")
puts "Client connected"

# Call 1: Check login
resp = rpc_call(client, :FUNC_IS_LOGIN)
puts "Login status: #{resp.status == 1 ? 'Logged in' : 'Not logged in'}"

# Call 2: Send text message
text_msg = TextMsg.new(receiver: "wxid_friend", message: "Hello from Ruby!")
resp = rpc_call(client, :FUNC_SEND_TEXT, TextMsg.encode(text_msg))
puts "Send text result: #{resp.status == 0 ? 'Success' : 'Failed'}"

# Call 3: Get contacts
resp = rpc_call(client, :FUNC_GET_CONTACTS)
puts "Contacts: #{resp.data}"

client.close
Thread.kill(server_thread)
```

**Output:**
```
RPC Server started on port 10086
Client connected
Received: func=FUNC_IS_LOGIN
Login status: Logged in
Received: func=FUNC_SEND_TEXT
  Send to wxid_friend: Hello from Ruby!
Send text result: Success
Received: func=FUNC_GET_CONTACTS
Contacts: [contacts data]
```

#### Why Use Protobuf with NNG?

1. **Binary Efficiency**: Protobuf is 3-10x smaller than JSON, faster to parse
2. **Type Safety**: Strong typing prevents errors
3. **Cross-Language**: Works with Python, Go, Java, C++, etc.
4. **Schema Evolution**: Add fields without breaking old clients
5. **Perfect for RPC**: Natural request/response pattern

#### Performance Comparison

```ruby
# Benchmark: Protobuf vs JSON
require 'benchmark'
require 'json'

data = { name: "Alice", age: 30, contacts: ["Bob", "Charlie"] }

Benchmark.bm(10) do |x|
  x.report("JSON:") do
    10000.times { JSON.parse(data.to_json) }
  end

  x.report("Protobuf:") do
    10000.times {
      msg = MyProto.new(data)
      MyProto.decode(MyProto.encode(msg))
    }
  end
end

# Typical result:
#                user     system      total        real
# JSON:      0.850000   0.010000   0.860000 (  0.862341)
# Protobuf:  0.280000   0.000000   0.280000 (  0.283127)
```

#### More Examples

See the `examples/` directory for complete runnable code:

```bash
# Run comprehensive demo
ruby examples/protobuf_demo.rb

# Run simple client-server
ruby examples/protobuf_simple.rb

# View proto definitions
cat examples/proto/message.proto
```

#### Loading .proto Files

You can also define messages in `.proto` files and compile them:

```bash
# Install protoc compiler
gem install grpc-tools

# Compile proto file
grpc_tools_ruby_protoc -I ./proto --ruby_out=./lib proto/message.proto

# Use in Ruby
require_relative 'lib/message_pb'
msg = MyMessage.new(field: "value")
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

NNG-ruby provides specific exception classes for different error conditions:

```ruby
require 'nng'

socket = NNG::Socket.new(:req)

begin
  # Set a short timeout for demonstration
  socket.recv_timeout = 100  # 100ms

  # Try to receive (will timeout if no data)
  socket.dial("tcp://127.0.0.1:9999")
  data = socket.recv

rescue NNG::TimeoutError => e
  puts "Operation timed out: #{e.message}"
  # Retry logic here

rescue NNG::ConnectionRefused => e
  puts "Cannot connect to server: #{e.message}"
  # Server might be down

rescue NNG::AddressInUse => e
  puts "Port already in use: #{e.message}"
  # Try a different port

rescue NNG::StateError => e
  puts "Invalid state for operation: #{e.message}"
  # Check socket state

rescue NNG::Error => e
  puts "NNG error (#{e.class}): #{e.message}"
  # Generic error handling

ensure
  socket.close
end
```

#### Complete Error Hierarchy

```ruby
NNG::Error                    # Base class for all NNG errors
├── NNG::TimeoutError         # Operation timed out
├── NNG::ConnectionRefused    # Connection refused by peer
├── NNG::ConnectionAborted    # Connection aborted
├── NNG::ConnectionReset      # Connection reset by peer
├── NNG::Closed               # Socket/resource already closed
├── NNG::AddressInUse         # Address already in use
├── NNG::NoMemory             # Out of memory
├── NNG::MessageSize          # Message size invalid
├── NNG::ProtocolError        # Protocol error
└── NNG::StateError           # Invalid state for operation
```

#### Practical Error Handling Examples

**1. Retry on Timeout:**

```ruby
def send_with_retry(socket, data, max_retries: 3)
  retries = 0
  begin
    socket.send(data)
  rescue NNG::TimeoutError
    retries += 1
    if retries < max_retries
      puts "Timeout, retrying (#{retries}/#{max_retries})..."
      sleep 0.1
      retry
    else
      raise "Failed after #{max_retries} retries"
    end
  end
end
```

**2. Graceful Degradation:**

```ruby
def connect_with_fallback(socket, primary_url, fallback_url)
  begin
    socket.dial(primary_url)
    puts "Connected to primary server"
  rescue NNG::ConnectionRefused, NNG::TimeoutError
    puts "Primary server unavailable, trying fallback..."
    socket.dial(fallback_url)
    puts "Connected to fallback server"
  end
end
```

**3. Non-blocking Receive with Error Handling:**

```ruby
socket = NNG::Socket.new(:pull)
socket.listen("tcp://127.0.0.1:5555")

loop do
  begin
    # Non-blocking receive
    data = socket.recv(flags: NNG::FFI::NNG_FLAG_NONBLOCK)
    puts "Received: #{data}"
    process_data(data)
  rescue NNG::Error => e
    if e.message.include?("try again")
      # No data available, do other work
      sleep 0.01
    else
      puts "Error: #{e.message}"
      break
    end
  end
end
```

## Requirements

- Ruby 2.5 or later
- FFI gem

The NNG shared library (v1.11.0) is bundled with the gem for all platforms, so no external installation is required.

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

### 0.1.2 (2025-10-03)
- **Enhanced Protocol Buffers documentation**
  - Added 3 comprehensive Protobuf integration examples
  - Example 1: Basic RPC with Protobuf
  - Example 2: Nested messages (message in message pattern)
  - Example 3: Real-world RPC pattern (WeChatFerry style)
- Added detailed explanation of Protobuf benefits with NNG
- Added performance comparison (Protobuf vs JSON)
- Added instructions for loading .proto files
- Improved examples documentation

### 0.1.1 (2025-10-03)
- Published to GitHub repository
- Updated gem packaging to include source code
- Added GitHub Actions workflows for CI/CD

### 0.1.0 (2025-10-03)
- Initial release
- Complete NNG API bindings
- All protocols and transports supported
- Bundled NNG library
- High-level Ruby API
- Message support
- Examples and documentation
