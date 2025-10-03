#!/usr/bin/env ruby
# frozen_string_literal: true

# NNG + Protocol Buffers 简单示例
# 演示如何在 NNG 通信中使用 Protobuf 序列化

require 'nng'
require 'google/protobuf'

puts "=" * 70
puts "NNG + Protocol Buffers 简单示例"
puts "=" * 70
puts

# ============================================================================
# 1. 定义 Protobuf 消息格式
# ============================================================================

puts "步骤 1: 定义 Protobuf 消息"
puts "-" * 70

# 定义请求消息
Google::Protobuf::DescriptorPool.generated_pool.build do
  add_file("request.proto", syntax: :proto3) do
    add_message "Request" do
      optional :id, :int32, 1
      optional :rpc_method, :string, 2
      optional :params, :string, 3
    end
  end
end

# 定义响应消息
Google::Protobuf::DescriptorPool.generated_pool.build do
  add_file("response.proto", syntax: :proto3) do
    add_message "Response" do
      optional :id, :int32, 1
      optional :status, :int32, 2
      optional :message, :string, 3
    end
  end
end

Request = Google::Protobuf::DescriptorPool.generated_pool.lookup("Request").msgclass
Response = Google::Protobuf::DescriptorPool.generated_pool.lookup("Response").msgclass

puts "✅ Protobuf 消息定义完成"
puts

# ============================================================================
# 2. 序列化和反序列化测试
# ============================================================================

puts "步骤 2: 测试 Protobuf 序列化"
puts "-" * 70

# 创建请求对象
request = Request.new(
  id: 12345,
  rpc_method: "getUserInfo",
  params: '{"user_id": 888}'
)

puts "原始请求对象:"
puts "  ID: #{request.id}"
puts "  Method: #{request.rpc_method}"
puts "  Params: #{request.params}"
puts

# 序列化为二进制
binary_data = Request.encode(request)
puts "序列化结果:"
puts "  大小: #{binary_data.bytesize} bytes"
puts "  十六进制: #{binary_data.unpack('H*').first}"
puts

# 反序列化
decoded_request = Request.decode(binary_data)
puts "反序列化结果:"
puts "  ID: #{decoded_request.id}"
puts "  Method: #{decoded_request.rpc_method}"
puts "  Params: #{decoded_request.params}"
puts

# ============================================================================
# 3. 使用进程模拟客户端-服务器通信
# ============================================================================

puts "步骤 3: NNG + Protobuf 通信演示"
puts "-" * 70

url = "tcp://127.0.0.1:15557"

# 创建服务器进程
server_pid = fork do
  begin
    server = NNG::Socket.new(:pair1)
    server.listen(url)
    puts "[服务器] 监听: #{url}"

    # 接收请求
    request_data = server.recv
    puts "[服务器] 收到 #{request_data.bytesize} bytes 数据"

    # 反序列化请求
    request = Request.decode(request_data)
    puts "[服务器] 解析请求:"
    puts "[服务器]   ID: #{request.id}"
    puts "[服务器]   Method: #{request.rpc_method}"
    puts "[服务器]   Params: #{request.params}"

    # 创建响应
    response = Response.new(
      id: request.id,
      status: 200,
      message: "处理成功: #{request.rpc_method}"
    )

    # 序列化并发送
    response_data = Response.encode(response)
    server.send(response_data)
    puts "[服务器] 发送响应 #{response_data.bytesize} bytes"

    server.close
  rescue => e
    puts "[服务器] 错误: #{e.message}"
  end
end

# 等待服务器启动
sleep 0.5

# 客户端
begin
  client = NNG::Socket.new(:pair1)
  client.dial(url)
  puts "[客户端] 连接: #{url}"

  # 创建请求
  request = Request.new(
    id: 99999,
    rpc_method: "getContacts",
    params: '{"limit": 100}'
  )

  # 序列化并发送
  request_data = Request.encode(request)
  puts "[客户端] 发送请求 #{request_data.bytesize} bytes"
  client.send(request_data)

  # 接收响应
  response_data = client.recv
  puts "[客户端] 收到响应 #{response_data.bytesize} bytes"

  # 反序列化
  response = Response.decode(response_data)
  puts "[客户端] 解析响应:"
  puts "[客户端]   ID: #{response.id}"
  puts "[客户端]   Status: #{response.status}"
  puts "[客户端]   Message: #{response.message}"

  client.close
rescue => e
  puts "[客户端] 错误: #{e.message}"
  puts e.backtrace.first(3)
end

# 等待服务器进程结束
Process.wait(server_pid)

puts
puts "=" * 70
puts "✅ 示例完成"
puts "=" * 70
puts
puts "关键代码:"
puts
puts "  # 序列化"
puts "  binary_data = Request.encode(request)"
puts "  socket.send(binary_data)"
puts
puts "  # 反序列化"
puts "  binary_data = socket.recv"
puts "  request = Request.decode(binary_data)"
puts
puts "优势:"
puts "  ✅ 类型安全的消息定义"
puts "  ✅ 高效的二进制序列化 (~50% 比 JSON 小)"
puts "  ✅ 跨语言兼容 (Python, Java, Go, C++ 等)"
puts "  ✅ 向后兼容的版本演进"
puts
