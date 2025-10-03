#!/usr/bin/env ruby
# frozen_string_literal: true

# NNG + Protocol Buffers 集成演示
# 展示如何将 Protobuf 消息通过 NNG 发送和接收

require 'google/protobuf'

puts "=" * 70
puts "NNG + Protocol Buffers 集成演示"
puts "=" * 70
puts

# ============================================================================
# 1. 定义 Protobuf 消息结构
# ============================================================================

puts "步骤 1: 定义 Protobuf 消息结构"
puts "-" * 70
puts

Google::Protobuf::DescriptorPool.generated_pool.build do
  add_file("wcf_rpc.proto", syntax: :proto3) do
    # RPC 请求消息
    add_message "RpcRequest" do
      optional :func_code, :int32, 1      # 功能码
      optional :data, :bytes, 2           # 业务数据
      optional :request_id, :string, 3    # 请求 ID
    end

    # RPC 响应消息
    add_message "RpcResponse" do
      optional :status, :int32, 1         # 状态码
      optional :data, :bytes, 2           # 响应数据
      optional :error_msg, :string, 3     # 错误消息
    end

    # 联系人信息
    add_message "Contact" do
      optional :wxid, :string, 1
      optional :name, :string, 2
      optional :remark, :string, 3
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
Contact = Google::Protobuf::DescriptorPool.generated_pool.lookup("Contact").msgclass
ContactList = Google::Protobuf::DescriptorPool.generated_pool.lookup("ContactList").msgclass
TextMessage = Google::Protobuf::DescriptorPool.generated_pool.lookup("TextMessage").msgclass

puts "✅ 消息定义完成:"
puts "   - RpcRequest (func_code, data, request_id)"
puts "   - RpcResponse (status, data, error_msg)"
puts "   - Contact (wxid, name, remark)"
puts "   - ContactList (contacts[])"
puts "   - TextMessage (receiver, content, aters)"
puts

# ============================================================================
# 2. 示例 1: 简单的请求-响应
# ============================================================================

puts "示例 1: 简单的 RPC 请求-响应"
puts "=" * 70
puts

# 客户端: 构建请求
request = RpcRequest.new(
  func_code: 0x01,        # FUNC_IS_LOGIN
  data: "",
  request_id: "req_001"
)

puts "📤 客户端构建请求:"
puts "   Function Code: 0x#{request.func_code.to_s(16)}"
puts "   Request ID: #{request.request_id}"
puts

# 序列化为二进制
request_binary = RpcRequest.encode(request)
puts "📦 序列化结果:"
puts "   大小: #{request_binary.bytesize} bytes"
puts "   十六进制: #{request_binary.unpack('H*').first[0, 40]}..."
puts

# 模拟通过 NNG 发送 (实际代码: socket.send(request_binary))
puts "🌐 通过 NNG 发送: socket.send(request_binary)"
puts

# 服务器: 接收并反序列化
# 模拟从 NNG 接收 (实际代码: response_binary = socket.recv)
puts "📥 服务器接收并解析:"
received_request = RpcRequest.decode(request_binary)
puts "   Function Code: 0x#{received_request.func_code.to_s(16)}"
puts "   Request ID: #{received_request.request_id}"
puts

# 服务器: 构建响应
response = RpcResponse.new(
  status: 0,
  data: [1].pack('C'),    # 返回 1 表示已登录
  error_msg: ""
)

puts "📤 服务器构建响应:"
puts "   Status: #{response.status} (成功)"
puts

# 序列化响应
response_binary = RpcResponse.encode(response)
puts "📦 序列化响应: #{response_binary.bytesize} bytes"
puts

# 模拟通过 NNG 发送响应
puts "🌐 通过 NNG 发送响应: socket.send(response_binary)"
puts

# 客户端: 接收并解析响应
received_response = RpcResponse.decode(response_binary)
puts "📥 客户端接收响应:"
puts "   Status: #{received_response.status}"
puts "   Is Login: #{received_response.data.unpack('C').first == 1}"
puts
puts

# ============================================================================
# 3. 示例 2: 嵌套消息 - 获取联系人列表
# ============================================================================

puts "示例 2: 嵌套消息 - 获取联系人列表"
puts "=" * 70
puts

# 客户端: 发送获取联系人请求
get_contacts_request = RpcRequest.new(
  func_code: 0x12,        # FUNC_GET_CONTACTS
  data: "",
  request_id: "req_002"
)

request_binary = RpcRequest.encode(get_contacts_request)
puts "📤 客户端发送请求: FUNC_GET_CONTACTS (#{request_binary.bytesize} bytes)"
puts

# 服务器: 构建联系人列表
contacts = ContactList.new(
  contacts: [
    Contact.new(wxid: "wxid_001", name: "张三", remark: "老同学"),
    Contact.new(wxid: "wxid_002", name: "李四", remark: "同事"),
    Contact.new(wxid: "wxid_003", name: "王五", remark: ""),
    Contact.new(wxid: "chatroom_001", name: "技术交流群", remark: "")
  ]
)

puts "🏗️  服务器构建联系人列表:"
contacts.contacts.each_with_index do |contact, i|
  puts "   #{i + 1}. #{contact.name} (#{contact.wxid})"
  puts "      备注: #{contact.remark}" unless contact.remark.empty?
end
puts

# 序列化联系人列表 (内层消息)
contacts_binary = ContactList.encode(contacts)
puts "📦 序列化联系人列表: #{contacts_binary.bytesize} bytes"
puts

# 构建 RPC 响应 (外层消息，包含内层数据)
contacts_response = RpcResponse.new(
  status: 0,
  data: contacts_binary,    # 嵌套的联系人列表
  error_msg: ""
)

response_binary = RpcResponse.encode(contacts_response)
puts "📦 序列化 RPC 响应: #{response_binary.bytesize} bytes"
puts "   (包含嵌套的联系人列表)"
puts

# 客户端: 接收并解析
puts "📥 客户端接收并解析:"

# 第一层: 解析 RPC 响应
rpc_resp = RpcResponse.decode(response_binary)
puts "   RPC Status: #{rpc_resp.status}"

# 第二层: 解析嵌套的联系人列表
contact_list = ContactList.decode(rpc_resp.data)
puts "   联系人数量: #{contact_list.contacts.size}"
puts

puts "📋 解析结果:"
contact_list.contacts.each_with_index do |contact, i|
  puts "   #{i + 1}. #{contact.name}"
  puts "      WXID: #{contact.wxid}"
  puts "      备注: #{contact.remark}" unless contact.remark.empty?
end
puts
puts

# ============================================================================
# 4. 示例 3: 发送文本消息
# ============================================================================

puts "示例 3: 发送文本消息"
puts "=" * 70
puts

# 客户端: 构建文本消息
text_msg = TextMessage.new(
  receiver: "wxid_001",
  content: "Hello from NNG + Protobuf!",
  aters: ""
)

puts "📝 客户端构建文本消息:"
puts "   接收者: #{text_msg.receiver}"
puts "   内容: #{text_msg.content}"
puts

# 序列化文本消息
text_msg_binary = TextMessage.encode(text_msg)
puts "📦 序列化文本消息: #{text_msg_binary.bytesize} bytes"
puts

# 构建 RPC 请求 (包含文本消息)
send_text_request = RpcRequest.new(
  func_code: 0x20,        # FUNC_SEND_TXT
  data: text_msg_binary,
  request_id: "req_003"
)

request_binary = RpcRequest.encode(send_text_request)
puts "📦 序列化 RPC 请求: #{request_binary.bytesize} bytes"
puts "🌐 通过 NNG 发送: socket.send(request_binary)"
puts

# 服务器: 接收并解析
puts "📥 服务器接收并解析:"
recv_request = RpcRequest.decode(request_binary)
puts "   Function Code: 0x#{recv_request.func_code.to_s(16)}"

# 解析嵌套的文本消息
recv_text_msg = TextMessage.decode(recv_request.data)
puts "   接收者: #{recv_text_msg.receiver}"
puts "   内容: #{recv_text_msg.content}"
puts

# 服务器: 发送消息并响应
puts "📨 服务器发送消息..."
send_response = RpcResponse.new(
  status: 0,
  data: [1].pack('C'),    # 1 = 发送成功
  error_msg: ""
)

response_binary = RpcResponse.encode(send_response)
puts "📤 服务器响应: 发送成功"
puts

# 客户端: 接收响应
final_response = RpcResponse.decode(response_binary)
puts "📥 客户端收到响应:"
if final_response.status == 0
  puts "   ✅ 消息发送成功"
else
  puts "   ❌ 发送失败: #{final_response.error_msg}"
end
puts
puts

# ============================================================================
# 5. 总结
# ============================================================================

puts "=" * 70
puts "✅ 演示完成"
puts "=" * 70
puts
puts "实际使用 NNG 的代码示例:"
puts
puts "  require 'nng'"
puts "  require 'google/protobuf'"
puts
puts "  # 客户端"
puts "  client = NNG::Socket.new(:pair1)"
puts "  client.dial('tcp://127.0.0.1:10086')"
puts
puts "  # 构建并发送 Protobuf 请求"
puts "  request = RpcRequest.new(func_code: 0x12, data: '', request_id: 'req_001')"
puts "  request_binary = RpcRequest.encode(request)"
puts "  client.send(request_binary)"
puts
puts "  # 接收并解析 Protobuf 响应"
puts "  response_binary = client.recv"
puts "  response = RpcResponse.decode(response_binary)"
puts
puts "  # 解析嵌套的业务数据"
puts "  contacts = ContactList.decode(response.data)"
puts
puts "  client.close"
puts
puts "关键技术点:"
puts
puts "1. 消息嵌套:"
puts "   RpcRequest/Response.data 字段 (bytes 类型) 可存储任意 Protobuf 消息"
puts
puts "2. 序列化链:"
puts "   业务消息 → encode → bytes → RPC 消息 → encode → bytes → NNG 发送"
puts
puts "3. 反序列化链:"
puts "   NNG 接收 → bytes → decode → RPC 消息 → bytes → decode → 业务消息"
puts
puts "4. 优势:"
puts "   ✅ 类型安全 - 编译时检查"
puts "   ✅ 高效编码 - 比 JSON 小 50%+"
puts "   ✅ 跨语言 - 与 Python/Java/Go/C++ 互通"
puts "   ✅ 版本兼容 - 可安全添加/删除字段"
puts "   ✅ 自动验证 - 自动检查必填字段"
puts
puts "5. 实际应用场景:"
puts "   • WeChatFerry RPC 通信"
puts "   • 微服务间调用"
puts "   • 分布式系统消息传递"
puts "   • 客户端-服务器协议"
puts
