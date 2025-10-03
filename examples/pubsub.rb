#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../lib/nng'

# Example: Publish/Subscribe protocol

puts "NNG Publish/Subscribe Protocol Example"
puts "=" * 50

# Create publisher socket
pub = NNG::Socket.new(:pub)
pub.listen("tcp://127.0.0.1:5557")
puts "Publisher listening on tcp://127.0.0.1:5557"

# Create subscribers in threads
sub_threads = 3.times.map do |i|
  Thread.new do
    sleep 0.5 # Give publisher time to start
    sub = NNG::Socket.new(:sub)
    sub.dial("tcp://127.0.0.1:5557")
    sub.set_option("sub:subscribe", "") # Subscribe to all topics
    puts "Subscriber #{i + 1} connected"

    # Receive 5 messages
    5.times do
      msg = sub.recv
      puts "Subscriber #{i + 1} received: #{msg}"
    end

    sub.close
  end
end

# Publisher sends 5 messages
sleep 1 # Give subscribers time to connect
5.times do |i|
  message = "Broadcast message #{i + 1}"
  pub.send(message)
  puts "Publisher sent: #{message}"
  sleep 0.2
end

# Wait for all subscribers
sub_threads.each(&:join)

# Cleanup
pub.close

puts "=" * 50
puts "Example completed!"
