#!/usr/bin/env ruby
# frozen_string_literal: true

# NNG + Protocol Buffers 示例 (使用线程)
# 演示 NNG 与 Protobuf 配合使用

require 'nng'
require 'google/protobuf'

puts "=" * 70
puts "NNG + Protocol Buffers 完整示例"
puts "=" * 70
puts

# ============================================================================
# 定义 Protobuf 消息
# ============================================================================

Google::Protobuf::DescriptorPool.generated_pool.build do
  add_file("rpc.proto", syntax: :proto3) do
    # RPC 请求
    add_message "RpcRequest" do
      optional :func_code, :int32, 1
      optional :data, :bytes, 2
      optional :request_id, :string, 3
    end

    # RPC 响应
    add_message "RpcResponse" do
      optional :status, :int32, 1
      optional :data, :bytes, 2
      optional :error_msg, :string, 3
    end

    # 联系人
    add_message "Contact" do
      optional :wxid, :string, 1
      optional :name, :string, 2
    end

    # 联系人列表
    add_message "ContactList" do
      repeated :contacts, :message, 1, "Contact"
    end
  end
end

RpcRequest = Google::Protobuf::DescriptorPool.generated_pool.lookup("RpcRequest").msgclass
RpcResponse = Google::Protobuf::DescriptorPool.generated_pool.lookup("RpcResponse").msgclass
Contact = Google::Protobuf::DescriptorPool.generated_pool.lookup("Contact").msgclass
ContactList = Google::Protobuf::DescriptorPool.generated_pool.lookup("ContactList").msgclass

puts "✅ Protobuf 消息定义完成"
puts

# ============================================================================
# 示例: 获取联系人列表 (使用嵌套的 Protobuf 消息)
# ============================================================================

puts "示例: RPC 调用 - 获取联系人列表"
puts "=" * 70
puts

url = "inproc://contacts_demo"  # 使用 inproc 避免端口冲突

# 创建 server socket (必须在 client 之前)
server_socket = NNG::Socket.new(:pair1)
server_socket.listen(url)
server_ready = true
puts "✅ 服务器监听: #{url}"
puts

# 服务器线程
server_thread = Thread.new do
  begin
    # 接收 RPC 请求
    request_data = server_socket.recv
    puts "📥 [服务器] 收到请求 (#{request_data.bytesize} bytes)"

    # 反序列化 RPC 请求
    rpc_request = RpcRequest.decode(request_data)
    puts "📋 [服务器] 解析 RPC 请求:"
    puts "    Function Code: 0x#{rpc_request.func_code.to_s(16)}"
    puts "    Request ID: #{rpc_request.request_id}"
    puts

    # 构建联系人列表 (嵌套消息)
    contacts = ContactList.new(
      contacts: [
        Contact.new(wxid: "wxid_001", name: "张三"),
        Contact.new(wxid: "wxid_002", name: "李四"),
        Contact.new(wxid: "wxid_003", name: "王五"),
        Contact.new(wxid: "chatroom_001", name: "技术交流群")
      ]
    )

    puts "🏗️  [服务器] 构建联系人列表:"
    puts "    联系人数量: #{contacts.contacts.size}"
    contacts.contacts.each_with_index do |contact, i|
      puts "    #{i + 1}. #{contact.name} (#{contact.wxid})"
    end
    puts

    # 序列化联系人列表 (内层)
    contacts_data = ContactList.encode(contacts)
    puts "📦 [服务器] 序列化联系人列表: #{contacts_data.bytesize} bytes"

    # 构建 RPC 响应 (外层)
    rpc_response = RpcResponse.new(
      status: 0,
      data: contacts_data,
      error_msg: ""
    )

    # 序列化 RPC 响应
    response_data = RpcResponse.encode(rpc_response)
    puts "📦 [服务器] 序列化 RPC 响应: #{response_data.bytesize} bytes"

    # 发送响应
    server_socket.send(response_data)
    puts "📤 [服务器] 响应已发送"
    puts

  rescue => e
    puts "❌ [服务器] 错误: #{e.message}"
  end
end

# 等待服务器准备好
sleep 0.1

# ============================================================================
# 客户端
# ============================================================================

puts "📞 [客户端] 发起 RPC 调用..."
puts

begin
  # 创建 client socket
  client_socket = NNG::Socket.new(:pair1)
  client_socket.dial(url)
  puts "✅ [客户端] 连接: #{url}"
  puts

  # 构建 RPC 请求
  rpc_request = RpcRequest.new(
    func_code: 0x12,  # 假设 0x12 = FUNC_GET_CONTACTS
    data: "",         # 本例无需参数
    request_id: "req_#{Time.now.to_i}"
  )

  puts "🏗️  [客户端] 构建 RPC 请求:"
  puts "    Function Code: 0x#{rpc_request.func_code.to_s(16)}"
  puts "    Request ID: #{rpc_request.request_id}"
  puts

  # 序列化并发送
  request_data = RpcRequest.encode(rpc_request)
  puts "📦 [客户端] 序列化请求: #{request_data.bytesize} bytes"
  client_socket.send(request_data)
  puts "📤 [客户端] 请求已发送"
  puts

  # 接收响应
  response_data = client_socket.recv
  puts "📥 [客户端] 收到响应 (#{response_data.bytesize} bytes)"

  # 反序列化 RPC 响应 (外层)
  rpc_response = RpcResponse.decode(response_data)
  puts "📋 [客户端] 解析 RPC 响应:"
  puts "    Status: #{rpc_response.status}"
  puts "    Error: #{rpc_response.error_msg}" unless rpc_response.error_msg.empty?
  puts

  if rpc_response.status == 0
    # 反序列化联系人列表 (内层)
    contacts = ContactList.decode(rpc_response.data)
    puts "📋 [客户端] 解析联系人列表:"
    puts "    总数: #{contacts.contacts.size}"
    puts

    contacts.contacts.each_with_index do |contact, i|
      puts "    #{i + 1}. #{contact.name}"
      puts "       WXID: #{contact.wxid}"
    end
  else
    puts "❌ [客户端] RPC 调用失败: #{rpc_response.error_msg}"
  end

  # 关闭
  client_socket.close

rescue => e
  puts "❌ [客户端] 错误: #{e.message}"
  puts e.backtrace.first(3)
end

# 等待服务器线程完成
server_thread.join
server_socket.close

puts
puts "=" * 70
puts "✅ 示例完成"
puts "=" * 70
puts
puts "技术要点:"
puts
puts "1. 消息嵌套:"
puts "   RpcRequest/Response 包含 bytes 类型的 data 字段"
puts "   data 字段可以存储任意 Protobuf 消息的序列化结果"
puts
puts "2. 序列化过程:"
puts "   内层: contacts → ContactList.encode → bytes"
puts "   外层: RpcRequest { data: bytes } → RpcRequest.encode → bytes"
puts "   发送: bytes → NNG socket.send"
puts
puts "3. 反序列化过程:"
puts "   接收: NNG socket.recv → bytes"
puts "   外层: bytes → RpcResponse.decode → RpcResponse"
puts "   内层: RpcResponse.data → ContactList.decode → contacts"
puts
puts "4. 优势:"
puts "   • 类型安全 - 编译时检查消息结构"
puts "   • 高效序列化 - 比 JSON 小 50%+"
puts "   • 跨语言 - Python/Java/Go/C++ 互通"
puts "   • 向后兼容 - 可安全添加字段"
puts "   • 自动文档 - .proto 文件即文档"
puts
puts "5. 实际应用:"
puts "   • 微服务 RPC 通信"
puts "   • 分布式系统消息传递"
puts "   • 客户端-服务器协议"
puts "   • 消息队列数据格式"
puts
