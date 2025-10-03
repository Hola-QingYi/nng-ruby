#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../lib/nng'

# Example: Pair protocol (bidirectional communication)

puts "NNG Pair Protocol Example"
puts "=" * 50

# Create server socket
server = NNG::Socket.new(:pair1)
server.listen("tcp://127.0.0.1:5555")
puts "Server listening on tcp://127.0.0.1:5555"

# Create client socket in a thread
client_thread = Thread.new do
  sleep 0.5 # Give server time to start
  client = NNG::Socket.new(:pair1)
  client.dial("tcp://127.0.0.1:5555")
  puts "Client connected"

  # Send message from client
  client.send("Hello from client!")
  puts "Client sent: Hello from client!"

  # Receive response
  response = client.recv
  puts "Client received: #{response}"

  client.close
end

# Server receives and responds
data = server.recv
puts "Server received: #{data}"

server.send("Hello from server!")
puts "Server sent: Hello from server!"

# Wait for client thread
client_thread.join

# Cleanup
server.close

puts "=" * 50
puts "Example completed!"
