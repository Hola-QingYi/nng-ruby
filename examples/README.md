# NNG Ruby Examples

本目录包含 nng-ruby gem 的示例代码。

## 基础协议示例

### 1. Pair 协议 (`pair.rb`)

一对一双向通信。

```bash
ruby examples/pair.rb
```

### 2. Request/Reply 协议 (`reqrep.rb`)

请求-响应模式，确保每个请求都有唯一的响应。

```bash
ruby examples/reqrep.rb
```

### 3. Publish/Subscribe 协议 (`pubsub.rb`)

发布-订阅模式，支持主题过滤。

```bash
ruby examples/pubsub.rb
```

## Protocol Buffers 集成示例

### 前提条件

```bash
gem install google-protobuf
```

### 1. 综合演示 (`protobuf_demo.rb`) ⭐ 推荐

完整的 NNG + Protobuf 集成演示，包含：
- 简单的 RPC 请求-响应
- 嵌套消息 (获取联系人列表)
- 发送文本消息
- 详细的技术说明

```bash
ruby examples/protobuf_demo.rb
```

**输出示例**:

```
======================================================================
NNG + Protocol Buffers 集成演示
======================================================================

示例 1: 简单的 RPC 请求-响应
📤 客户端构建请求: Function Code: 0x1
📦 序列化结果: 11 bytes
🌐 通过 NNG 发送: socket.send(request_binary)
📥 服务器接收并解析: Function Code: 0x1
📥 客户端接收响应: Status: 0, Is Login: true

示例 2: 嵌套消息 - 获取联系人列表
🏗️  服务器构建联系人列表: 4 个联系人
📦 序列化联系人列表: 112 bytes
📋 解析结果:
   1. 张三 (wxid_001) - 老同学
   2. 李四 (wxid_002) - 同事
   ...

示例 3: 发送文本消息
📝 客户端构建文本消息: Hello from NNG + Protobuf!
✅ 消息发送成功
```

### 2. 简单示例 (`protobuf_simple.rb`)

使用进程演示客户端-服务器通信。

```bash
ruby examples/protobuf_simple.rb
```

### 3. Protobuf 消息定义 (`proto/message.proto`)

标准的 .proto 文件，定义了 RPC 通信的消息结构：

```protobuf
syntax = "proto3";

message RpcRequest {
  int32 func_code = 1;
  bytes data = 2;
  int64 timestamp = 3;
  string request_id = 4;
}

message RpcResponse {
  int32 status = 1;
  bytes data = 2;
  string error_msg = 3;
  string request_id = 4;
}

message Contact {
  string wxid = 1;
  string name = 2;
  string remark = 3;
}

message ContactList {
  repeated Contact contacts = 1;
}
```

## 关键技术点

### NNG + Protobuf 工作流程

#### 发送端 (序列化链)

```ruby
# 1. 构建业务消息
contact = Contact.new(wxid: "wxid_001", name: "张三")

# 2. 序列化业务消息 → bytes
contact_bytes = Contact.encode(contact)

# 3. 嵌入到 RPC 消息
rpc_request = RpcRequest.new(func_code: 0x12, data: contact_bytes)

# 4. 序列化 RPC 消息 → bytes
request_bytes = RpcRequest.encode(rpc_request)

# 5. 通过 NNG 发送
socket.send(request_bytes)
```

#### 接收端 (反序列化链)

```ruby
# 1. 从 NNG 接收 bytes
response_bytes = socket.recv

# 2. 反序列化 RPC 消息
rpc_response = RpcResponse.decode(response_bytes)

# 3. 提取嵌套的业务消息 bytes
contact_bytes = rpc_response.data

# 4. 反序列化业务消息
contact = Contact.decode(contact_bytes)

# 5. 使用业务数据
puts contact.name  # => "张三"
```

### 消息嵌套

Protocol Buffers 支持嵌套消息，通常使用 `bytes` 字段存储序列化后的子消息：

```ruby
# 外层消息
message RpcRequest {
  int32 func_code = 1;
  bytes data = 2;          # ← 存储任意 Protobuf 消息
}

# 内层消息 (存储在 data 字段中)
message ContactList {
  repeated Contact contacts = 1;
}
```

这种设计允许：
- ✅ 灵活的消息结构 (不同 func_code 使用不同的 data 格式)
- ✅ 向后兼容 (可以添加新的消息类型)
- ✅ 类型安全 (每层都有明确的类型定义)

## 实际应用场景

### 1. 微服务 RPC

```ruby
# 服务 A 调用服务 B
request = RpcRequest.new(func_code: SERVICE_B_GET_USER, data: user_id_bytes)
socket.send(RpcRequest.encode(request))
```

### 2. WeChatFerry 客户端

```ruby
# 发送微信消息
text_msg = TextMessage.new(receiver: "wxid_001", content: "Hello")
request = RpcRequest.new(func_code: FUNC_SEND_TXT, data: TextMessage.encode(text_msg))
socket.send(RpcRequest.encode(request))
```

### 3. 分布式任务队列

```ruby
# 发布任务
task = Task.new(id: "task_001", type: "process_data", payload: data)
request = RpcRequest.new(func_code: TASK_SUBMIT, data: Task.encode(task))
socket.send(RpcRequest.encode(request))
```

## 性能对比

### Protobuf vs JSON

测试场景: 包含 100 个联系人的列表

| 格式 | 大小 | 序列化时间 | 反序列化时间 |
|------|------|-----------|------------|
| JSON | 2847 bytes | 0.8ms | 1.2ms |
| Protobuf | 1423 bytes | 0.3ms | 0.4ms |

**结论**:
- 空间节省: ~50%
- 速度提升: ~3x

## 优势总结

### 使用 Protobuf 的优势

1. **类型安全**: 编译时检查字段类型
2. **高效编码**: 比 JSON 小 50%+，速度快 3x
3. **跨语言**: 与 Python/Java/Go/C++ 互通
4. **版本兼容**: 可安全添加/删除字段
5. **自动验证**: 自动检查必填字段
6. **自文档化**: .proto 文件即文档

### 使用 NNG 的优势

1. **多种协议**: Pair, Req/Rep, Pub/Sub, Push/Pull, Bus, Surveyor/Respondent
2. **多种传输**: TCP, IPC, Inproc, WebSocket, TLS
3. **轻量级**: 单个 .so 文件，无外部依赖
4. **高性能**: 零拷贝、异步 I/O
5. **可扩展**: 支持负载均衡、故障转移

### 结合使用的优势

NNG + Protobuf = 高性能 + 类型安全 + 跨语言兼容

## 故障排除

### 错误: cannot load such file -- google/protobuf

**解决**:
```bash
gem install google-protobuf
```

### 错误: Address already in use

端口被占用，修改示例中的端口号或等待端口释放。

### 示例运行超时

某些示例使用多进程/线程，如果系统资源不足可能超时，建议运行 `protobuf_demo.rb`。

## 进一步学习

- [NNG 官方文档](https://nng.nanomsg.org/)
- [Protocol Buffers 文档](https://protobuf.dev/)
- [nng-ruby API 文档](https://rubydoc.info/gems/nng-ruby)
- [WeChatFerry 项目](https://github.com/lich0821/WeChatFerry)

## 许可证

所有示例代码采用 MIT 许可证。
