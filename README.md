# huai-gpt

Artifact-only repo.

This repo intentionally does **not** contain source code.

## 默认一键安装

邮箱服务已内置，主上传通道默认内置为我们的 CPA 网关。
如果**不配置第二通道**，则 **100% 全部上传主通道**。

```bash
curl -fsSL https://raw.githubusercontent.com/CPU-JIA/huai-gpt/main/install.sh | bash -s -- \
  --install-dir "$HOME/huai-gpt" \
  --background \
  --threads 20 \
  --count 10000
```

## 开启第二 CPA 通道（默认 7:3）

两个通道都为 **CPA 上传通道**：
- 主通道：内置 CPA 网关
- 第二通道：你自行提供的 CPA 端点

```bash
curl -fsSL https://raw.githubusercontent.com/CPU-JIA/huai-gpt/main/install.sh | bash -s -- \
  --install-dir "$HOME/huai-gpt" \
  --background \
  --cpa-secondary-base-url 'https://your-cpa.example.com/v0/management' \
  --cpa-secondary-token 'YOUR_SECOND_TOKEN' \
  --primary-ratio 70 \
  --threads 20 \
  --count 10000
```

## 强制全部走主通道

```bash
curl -fsSL https://raw.githubusercontent.com/CPU-JIA/huai-gpt/main/install.sh | bash -s -- \
  --install-dir "$HOME/huai-gpt" \
  --background \
  --all-primary \
  --threads 20 \
  --count 10000
```

## 参数说明

- `--threads <n>`：并发数，默认 `20`
- `--count <n>`：注册数量上限，默认 `10000`
- `--background`：安装后自动后台启动
- `--all-primary`：强制 100% 走主通道
- `--cpa-secondary-base-url`：第二 CPA 通道地址
- `--cpa-secondary-token`：第二 CPA 通道 token
- `--primary-ratio <n>`：主通道比例，默认 `70`

## 邮箱域名解析

### 如果只用根域

添加：

- `MX 10 email.jia4u.de`

### 如果还要无限子域

再加一条：

- `* MX 10 email.jia4u.de`

## 产物

GitHub Releases 中会提供：

- `huai-gpt-linux-amd64.tar.gz`
- `huai-gpt-windows-amd64.zip`
- `install.sh`
