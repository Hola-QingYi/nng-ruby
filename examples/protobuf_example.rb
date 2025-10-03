#!/usr/bin/env ruby
# frozen_string_literal: true

# Protocol Buffers + NNG 示例
# 演示如何在 NNG 通信中使用 Protobuf 序列化

require 'nng'
require 'google/protobuf'

puts "=" * 70
puts "NNG + Protocol Buffers 示例"
puts "=" * 70
puts

# ============================================================================
# 1. 定义 Protobuf 消息格式
# ============================================================================

puts "1. 定义 Protobuf 消息格式"
puts "-" * 70

# 定义请求消息
Google::Protobuf::DescriptorPool.generated_pool.build do
  add_file("request.proto", syntax: :proto3) do
    add_message "Request" do
      optional :id, :int32, 1
      optional :method, :string, 2
      optional :params, :string, 3
      optional :timestamp, :int64, 4
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
      optional :data, :string, 4
    end
  end
end

Request = Google::Protobuf::DescriptorPool.generated_pool.lookup("Request").msgclass
Response = Google::Protobuf::DescriptorPool.generated_pool.lookup("Response").msgclass

puts "✅ Protobuf 消息定义完成"
puts "   - Request: id, method, params, timestamp"
puts "   - Response: id, status, message, data"
puts

# ============================================================================
# 2. 启动服务器线程
# ============================================================================

puts "2. 启动 NNG 服务器 (Pair1 协议)"
puts "-" * 70

server_url = "tcp://127.0.0.1:15555"
server_ready = false

server_thread = Thread.new do
  server = NNG::Socket.new(:pair1)
  server.listen(server_url)
  server_ready = true
  puts "✅ 服务器监听: #{server_url}"
  puts

  # 接收请求
  request_data = server.recv
  request = Request.decode(request_data)

  puts "📥 服务器收到请求:"
  puts "   ID: #{request.id}"
  puts "   Method: #{request.method}"
  puts "   Params: #{request.params}"
  puts "   Timestamp: #{Time.at(request.timestamp)}"
  puts

  # 处理请求并构建响应
  response = Response.new(
    id: request.id,
    status: 200,
    message: "Success",
    data: "Hello from server! Processed: #{request.method}"
  )

  # 序列化并发送响应
  response_data = Response.encode(response)
  server.send(response_data)

  puts "📤 服务器发送响应:"
  puts "   Status: #{response.status}"
  puts "   Message: #{response.message}"
  puts "   Data: #{response.data}"
  puts

  server.close
end

# 等待服务器准备好
sleep 0.1 until server_ready

# ============================================================================
# 3. 客户端发送请求
# ============================================================================

puts "3. 启动 NNG 客户端 (Pair1 协议)"
puts "-" * 70

client = NNG::Socket.new(:pair1)
client.dial(server_url)
puts "✅ 客户端连接: #{server_url}"
puts

# 构建请求
request = Request.new(
  id: 12345,
  method: "getUserInfo",
  params: '{"user_id": 888}',
  timestamp: Time.now.to_i
)

puts "📤 客户端发送请求:"
puts "   ID: #{request.id}"
puts "   Method: #{request.method}"
puts "   Params: #{request.params}"
puts

# 序列化并发送
request_data = Request.encode(request)
puts "   序列化后大小: #{request_data.bytesize} bytes"
puts

client.send(request_data)

# 接收响应
response_data = client.recv
response = Response.decode(response_data)

puts "📥 客户端收到响应:"
puts "   ID: #{response.id}"
puts "   Status: #{response.status}"
puts "   Message: #{response.message}"
puts "   Data: #{response.data}"
puts

client.close

# 等待服务器线程结束
server_thread.join

# ============================================================================
# 4. 高级示例：使用嵌套消息
# ============================================================================

puts "=" * 70
puts "4. 高级示例：嵌套 Protobuf 消息"
puts "=" * 70
puts

# 定义复杂的嵌套消息
Google::Protobuf::DescriptorPool.generated_pool.build do
  add_file("user.proto", syntax: :proto3) do
    add_message "User" do
      optional :id, :int32, 1
      optional :name, :string, 2
      optional :email, :string, 3
      repeated :tags, :string, 4
    end

    add_message "UserRequest" do
      optional :action, :string, 1
      optional :user, :message, 2, "User"
    end

    add_message "UserResponse" do
      optional :success, :bool, 1
      optional :user, :message, 2, "User"
      optional :error, :string, 3
    end
  end
end

User = Google::Protobuf::DescriptorPool.generated_pool.lookup("User").msgclass
UserRequest = Google::Protobuf::DescriptorPool.generated_pool.lookup("UserRequest").msgclass
UserResponse = Google::Protobuf::DescriptorPool.generated_pool.lookup("UserResponse").msgclass

# 创建复杂消息
user = User.new(
  id: 1001,
  name: "张三",
  email: "zhangsan@example.com",
  tags: ["VIP", "早期用户", "活跃"]
)

user_request = UserRequest.new(
  action: "create",
  user: user
)

puts "创建嵌套消息:"
puts "  Action: #{user_request.action}"
puts "  User:"
puts "    ID: #{user_request.user.id}"
puts "    Name: #{user_request.user.name}"
puts "    Email: #{user_request.user.email}"
puts "    Tags: #{user_request.user.tags.join(', ')}"
puts

# 序列化
serialized = UserRequest.encode(user_request)
puts "序列化后大小: #{serialized.bytesize} bytes"
puts

# 反序列化
deserialized = UserRequest.decode(serialized)
puts "反序列化成功:"
puts "  User Name: #{deserialized.user.name}"
puts "  User Tags: #{deserialized.user.tags.join(', ')}"
puts

# ============================================================================
# 5. 实际应用：RPC 调用示例
# ============================================================================

puts "=" * 70
puts "5. 实际应用：完整 RPC 调用"
puts "=" * 70
puts

# 定义 RPC 消息
Google::Protobuf::DescriptorPool.generated_pool.build do
  add_file("rpc.proto", syntax: :proto3) do
    add_message "RpcRequest" do
      optional :func_code, :int32, 1
      optional :data, :bytes, 2
    end

    add_message "RpcResponse" do
      optional :status, :int32, 1
      optional :data, :bytes, 2
      optional :error_msg, :string, 3
    end
  end
end

RpcRequest = Google::Protobuf::DescriptorPool.generated_pool.lookup("RpcRequest").msgclass
RpcResponse = Google::Protobuf::DescriptorPool.generated_pool.lookup("RpcResponse").msgclass

# 模拟 RPC 服务器
rpc_url = "tcp://127.0.0.1:15556"
rpc_server_ready = false

rpc_server = Thread.new do
  server = NNG::Socket.new(:pair1)
  server.listen(rpc_url)
  rpc_server_ready = true

  # 接收 RPC 请求
  request_data = server.recv
  rpc_request = RpcRequest.decode(request_data)

  puts "🔧 RPC 服务器收到调用:"
  puts "   Function Code: 0x#{rpc_request.func_code.to_s(16)}"
  puts "   Data Size: #{rpc_request.data.bytesize} bytes"
  puts

  # 解析嵌套的用户数据
  user_data = User.decode(rpc_request.data)
  puts "   解析用户数据:"
  puts "     Name: #{user_data.name}"
  puts "     Email: #{user_data.email}"
  puts

  # 构建响应
  result_user = User.new(
    id: user_data.id,
    name: user_data.name,
    email: user_data.email,
    tags: user_data.tags + ["已处理"]
  )

  rpc_response = RpcResponse.new(
    status: 0,
    data: User.encode(result_user),
    error_msg: ""
  )

  # 发送响应
  server.send(RpcResponse.encode(rpc_response))
  puts "✅ RPC 响应已发送"
  puts

  server.close
end

sleep 0.1 until rpc_server_ready

# RPC 客户端
puts "📞 RPC 客户端发起调用..."
puts

client = NNG::Socket.new(:pair1)
client.dial(rpc_url)

# 准备调用参数
call_user = User.new(
  id: 2001,
  name: "李四",
  email: "lisi@example.com",
  tags: ["新用户"]
)

# 构建 RPC 请求
rpc_request = RpcRequest.new(
  func_code: 0x10,  # 假设 0x10 是 getUserInfo 的功能码
  data: User.encode(call_user)
)

# 发送请求
client.send(RpcRequest.encode(rpc_request))

# 接收响应
response_data = client.recv
rpc_response = RpcResponse.decode(response_data)

puts "📥 RPC 客户端收到响应:"
puts "   Status: #{rpc_response.status}"

if rpc_response.status == 0
  result_user = User.decode(rpc_response.data)
  puts "   结果:"
  puts "     Name: #{result_user.name}"
  puts "     Email: #{result_user.email}"
  puts "     Tags: #{result_user.tags.join(', ')}"
else
  puts "   Error: #{rpc_response.error_msg}"
end
puts

client.close
rpc_server.join

# ============================================================================
# 总结
# ============================================================================

puts "=" * 70
puts "✅ 示例完成"
puts "=" * 70
puts
puts "关键要点:"
puts "  1. ✅ 使用 Protobuf 定义消息格式"
puts "  2. ✅ 使用 encode 序列化消息"
puts "  3. ✅ 使用 NNG 发送二进制数据"
puts "  4. ✅ 使用 NNG 接收二进制数据"
puts "  5. ✅ 使用 decode 反序列化消息"
puts
puts "优势:"
puts "  • 类型安全的消息格式"
puts "  • 高效的二进制序列化"
puts "  • 跨语言兼容"
puts "  • 版本演进支持"
puts "  • 自动代码生成"
puts
puts "适用场景:"
puts "  • 微服务 RPC 通信"
puts "  • 分布式系统消息传递"
puts "  • 高性能数据交换"
puts "  • 跨语言服务集成"
puts
