#!/usr/bin/env ruby
# frozen_string_literal: true

# NNG + Protocol Buffers 高级示例
# 使用 .proto 文件和复杂的消息嵌套

require 'nng'
require 'google/protobuf'

puts "=" * 70
puts "NNG + Protocol Buffers 高级示例"
puts "使用 .proto 文件和消息嵌套"
puts "=" * 70
puts

# ============================================================================
# 1. 从 .proto 文件生成 Ruby 代码 (编译时)
# ============================================================================

puts "说明: 使用 .proto 文件"
puts "-" * 70
puts
puts "实际项目中应该使用 protoc 编译 .proto 文件:"
puts "  $ protoc --ruby_out=. proto/message.proto"
puts
puts "本示例直接在 Ruby 中定义消息 (等效于编译后的代码)"
puts

# 定义消息 (等效于从 message.proto 编译生成)
Google::Protobuf::DescriptorPool.generated_pool.build do
  add_file("message.proto", syntax: :proto3) do
    # RPC 请求
    add_message "RpcRequest" do
      optional :func_code, :int32, 1
      optional :data, :bytes, 2
      optional :timestamp, :int64, 3
      optional :request_id, :string, 4
    end

    # RPC 响应
    add_message "RpcResponse" do
      optional :status, :int32, 1
      optional :data, :bytes, 2
      optional :error_msg, :string, 3
      optional :request_id, :string, 4
    end

    # 用户
    add_message "User" do
      optional :id, :int32, 1
      optional :name, :string, 2
      optional :email, :string, 3
      repeated :tags, :string, 4
    end

    # 联系人
    add_message "Contact" do
      optional :wxid, :string, 1
      optional :name, :string, 2
      optional :remark, :string, 3
      optional :contact_type, :int32, 4
    end

    # 联系人列表
    add_message "ContactList" do
      repeated :contacts, :message, 1, "Contact"
    end

    # 文本消息
    add_message "TextMessage" do
      optional :receiver, :string, 1
      optional :content, :string, 2
      optional :aters, :string, 3
    end
  end
end

# 获取消息类
RpcRequest = Google::Protobuf::DescriptorPool.generated_pool.lookup("RpcRequest").msgclass
RpcResponse = Google::Protobuf::DescriptorPool.generated_pool.lookup("RpcResponse").msgclass
User = Google::Protobuf::DescriptorPool.generated_pool.lookup("User").msgclass
Contact = Google::Protobuf::DescriptorPool.generated_pool.lookup("Contact").msgclass
ContactList = Google::Protobuf::DescriptorPool.generated_pool.lookup("ContactList").msgclass
TextMessage = Google::Protobuf::DescriptorPool.generated_pool.lookup("TextMessage").msgclass

puts "✅ Protobuf 消息类加载完成"
puts

# ============================================================================
# 2. 示例 1: 嵌套消息 - 获取联系人列表
# ============================================================================

puts "示例 1: 嵌套消息 - 获取联系人列表"
puts "=" * 70
puts

url1 = "tcp://127.0.0.1:15560"

# 服务器进程
server1_pid = fork do
  server = NNG::Socket.new(:pair1)
  server.listen(url1)
  puts "[服务器] 监听: #{url1}"

  # 接收 RPC 请求
  request_data = server.recv
  rpc_request = RpcRequest.decode(request_data)

  puts "[服务器] 收到 RPC 调用:"
  puts "[服务器]   Function: 0x#{rpc_request.func_code.to_s(16)}"
  puts "[服务器]   Request ID: #{rpc_request.request_id}"
  puts "[服务器]   Timestamp: #{Time.at(rpc_request.timestamp)}"

  # 构建联系人列表
  contacts = ContactList.new(
    contacts: [
      Contact.new(wxid: "wxid_001", name: "张三", remark: "老同学", contact_type: 1),
      Contact.new(wxid: "wxid_002", name: "李四", remark: "同事", contact_type: 1),
      Contact.new(wxid: "chatroom_001", name: "技术交流群", remark: "", contact_type: 2)
    ]
  )

  puts "[服务器] 构建响应: #{contacts.contacts.size} 个联系人"

  # 编码嵌套消息
  contacts_data = ContactList.encode(contacts)

  # 构建 RPC 响应
  rpc_response = RpcResponse.new(
    status: 0,
    data: contacts_data,
    error_msg: "",
    request_id: rpc_request.request_id
  )

  # 发送响应
  server.send(RpcResponse.encode(rpc_response))
  puts "[服务器] 响应已发送"

  server.close
end

sleep 0.5

# 客户端
client1 = NNG::Socket.new(:pair1)
client1.dial(url1)
puts "[客户端] 连接: #{url1}"

# 构建 RPC 请求
rpc_request = RpcRequest.new(
  func_code: 0x12,  # FUNC_GET_CONTACTS
  data: "",
  timestamp: Time.now.to_i,
  request_id: "req_#{Time.now.to_i}_001"
)

puts "[客户端] 发送 RPC 请求:"
puts "[客户端]   Function: 0x#{rpc_request.func_code.to_s(16)}"
puts "[客户端]   Request ID: #{rpc_request.request_id}"

# 发送请求
client1.send(RpcRequest.encode(rpc_request))

# 接收响应
response_data = client1.recv
rpc_response = RpcResponse.decode(response_data)

puts "[客户端] 收到 RPC 响应:"
puts "[客户端]   Status: #{rpc_response.status}"
puts "[客户端]   Request ID: #{rpc_response.request_id}"

if rpc_response.status == 0
  # 解析嵌套的联系人列表
  contacts = ContactList.decode(rpc_response.data)
  puts "[客户端] 解析联系人列表 (#{contacts.contacts.size} 个):"

  contacts.contacts.each_with_index do |contact, i|
    puts "[客户端]   #{i + 1}. #{contact.name} (#{contact.wxid})"
    puts "[客户端]      备注: #{contact.remark}" unless contact.remark.empty?
    puts "[客户端]      类型: #{contact.contact_type == 1 ? '好友' : '群聊'}"
  end
else
  puts "[客户端] 错误: #{rpc_response.error_msg}"
end

client1.close
Process.wait(server1_pid)

puts
puts

# ============================================================================
# 3. 示例 2: 发送文本消息
# ============================================================================

puts "示例 2: 发送文本消息"
puts "=" * 70
puts

url2 = "tcp://127.0.0.1:15561"

# 服务器进程
server2_pid = fork do
  server = NNG::Socket.new(:pair1)
  server.listen(url2)
  puts "[服务器] 监听: #{url2}"

  # 接收 RPC 请求
  request_data = server.recv
  rpc_request = RpcRequest.decode(request_data)

  puts "[服务器] 收到 RPC 调用:"
  puts "[服务器]   Function: 0x#{rpc_request.func_code.to_s(16)}"

  # 解析文本消息参数
  text_msg = TextMessage.decode(rpc_request.data)
  puts "[服务器] 解析文本消息:"
  puts "[服务器]   接收者: #{text_msg.receiver}"
  puts "[服务器]   内容: #{text_msg.content}"
  puts "[服务器]   @的人: #{text_msg.aters}" unless text_msg.aters.empty?

  # 模拟发送消息
  puts "[服务器] 发送消息..."
  sleep 0.1
  puts "[服务器] 消息发送成功"

  # 构建响应
  rpc_response = RpcResponse.new(
    status: 0,
    data: [1].pack('C'),  # 返回 1 表示成功
    error_msg: "",
    request_id: rpc_request.request_id
  )

  server.send(RpcResponse.encode(rpc_response))
  server.close
end

sleep 0.5

# 客户端
client2 = NNG::Socket.new(:pair1)
client2.dial(url2)
puts "[客户端] 连接: #{url2}"

# 构建文本消息
text_msg = TextMessage.new(
  receiver: "wxid_001",
  content: "Hello from NNG + Protobuf!",
  aters: ""
)

# 编码为字节
text_msg_data = TextMessage.encode(text_msg)

# 构建 RPC 请求
rpc_request = RpcRequest.new(
  func_code: 0x20,  # FUNC_SEND_TXT
  data: text_msg_data,
  timestamp: Time.now.to_i,
  request_id: "req_#{Time.now.to_i}_002"
)

puts "[客户端] 发送文本消息:"
puts "[客户端]   接收者: #{text_msg.receiver}"
puts "[客户端]   内容: #{text_msg.content}"

# 发送请求
client2.send(RpcRequest.encode(rpc_request))

# 接收响应
response_data = client2.recv
rpc_response = RpcResponse.decode(response_data)

puts "[客户端] 收到响应:"
if rpc_response.status == 0
  puts "[客户端]   ✅ 消息发送成功"
else
  puts "[客户端]   ❌ 发送失败: #{rpc_response.error_msg}"
end

client2.close
Process.wait(server2_pid)

puts
puts

# ============================================================================
# 总结
# ============================================================================

puts "=" * 70
puts "✅ 示例完成"
puts "=" * 70
puts
puts "关键技术点:"
puts
puts "1. 消息嵌套:"
puts "   RpcRequest { data: ContactList { contacts: [Contact, ...] } }"
puts
puts "2. 序列化链:"
puts "   内层: ContactList.encode(contacts) → bytes"
puts "   外层: RpcRequest.encode(request) → bytes"
puts
puts "3. 反序列化链:"
puts "   外层: RpcRequest.decode(bytes) → request"
puts "   内层: ContactList.decode(request.data) → contacts"
puts
puts "4. 实际应用场景:"
puts "   • RPC 框架 (如本例)"
puts "   • 微服务通信"
puts "   • 消息队列"
puts "   • 分布式系统数据交换"
puts
puts "5. 优势:"
puts "   ✅ 强类型约束"
puts "   ✅ 自动编解码"
puts "   ✅ 跨语言兼容"
puts "   ✅ 高效序列化"
puts "   ✅ 版本向后兼容"
puts
