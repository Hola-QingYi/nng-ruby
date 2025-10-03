#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../lib/nng'

# Example: Request/Reply protocol

puts "NNG Request/Reply Protocol Example"
puts "=" * 50

# Create reply (server) socket
rep = NNG::Socket.new(:rep)
rep.listen("tcp://127.0.0.1:5556")
puts "Reply server listening on tcp://127.0.0.1:5556"

# Create request (client) socket in a thread
req_thread = Thread.new do
  sleep 0.5 # Give server time to start
  req = NNG::Socket.new(:req)
  req.dial("tcp://127.0.0.1:5556")
  puts "Request client connected"

  # Send 3 requests
  3.times do |i|
    request = "Request #{i + 1}"
    req.send(request)
    puts "Client sent: #{request}"

    response = req.recv
    puts "Client received: #{response}"
    sleep 0.1
  end

  req.close
end

# Server handles 3 requests
3.times do |i|
  request = rep.recv
  puts "Server received: #{request}"

  reply = "Reply to #{request}"
  rep.send(reply)
  puts "Server sent: #{reply}"
end

# Wait for client thread
req_thread.join

# Cleanup
rep.close

puts "=" * 50
puts "Example completed!"
