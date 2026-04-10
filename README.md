# huai-gpt

Artifact-only repo.

This repo intentionally does **not** contain source code.

## 默认安装（主 CPA）

邮箱服务已内置。
两个上传通道都走老 CPA 管理端；如果**不配置第二通道**，则 **100% 全部上传主通道**。

```bash
curl -fsSL https://raw.githubusercontent.com/CPU-JIA/huai-gpt/main/install.sh | bash -s -- \
  --install-dir "$HOME/huai-gpt" \
  --worker-count 20 \
  --target-count 10000 \
  --run-mode fixed \
  --panel-port 26410
```

## 双老 CPA 通道（70/30）

- 主通道：默认预置
- 第二通道：你自行提供

```bash
curl -fsSL https://raw.githubusercontent.com/CPU-JIA/huai-gpt/main/install.sh | bash -s -- \
  --install-dir "$HOME/huai-gpt" \
  --secondary-cpa-url 'https://your-cpa.example.com' \
  --secondary-cpa-token 'YOUR_SECOND_TOKEN' \
  --primary-share 70 \
  --worker-count 20 \
  --target-count 10000 \
  --run-mode fixed \
  --panel-port 26410
```

## 强制全走主 CPA

```bash
curl -fsSL https://raw.githubusercontent.com/CPU-JIA/huai-gpt/main/install.sh | bash -s -- \
  --install-dir "$HOME/huai-gpt" \
  --primary-only \
  --worker-count 20 \
  --target-count 10000 \
  --run-mode fixed \
  --panel-port 26410
```

## 面板

- 默认地址：`http://<server-ip>:26410`
- 面板 Token：安装时自动生成并打印
- 鉴权方式：Token 登录

## 参数说明

- `--worker-count <n>`：并发数，默认 `20`
- `--target-count <n>`：目标数量，默认 `10000`
- `--run-mode <fixed|replenish>`：固定成功数 / 补号模式
- `--panel-port <n>`：面板端口，默认 `26410`
- `--panel-token <token>`：自定义面板 token
- `--primary-only`：强制 100% 走主通道
- `--primary-cpa-url`：主 CPA 地址
- `--primary-cpa-token`：主 CPA token
- `--secondary-cpa-url`：第二 CPA 地址
- `--secondary-cpa-token`：第二 CPA token
- `--primary-share <n>`：主通道比例，默认 `70`

## 邮箱域名解析

### 如果只用根域

- `MX 10 email.jia4u.de`

### 如果还要无限子域

- `* MX 10 email.jia4u.de`

## 产物

GitHub Releases 中会提供：

- `huai-gpt-linux-amd64.tar.gz`
- `huai-gpt-windows-amd64.zip`
- `install.sh`
