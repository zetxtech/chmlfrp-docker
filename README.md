# chmlfrp-docker

把 [ChmlFrp 面板](https://panel.chmlfrp.net/tunnel/download) 发布的 frpc 客户端自动打包成多架构 Docker 镜像。用法与 frpc 官方镜像一致：配置放在 `/etc/frp/frpc.toml`，入口是 `/usr/bin/frpc`。

镜像地址：`ghcr.io/zetxtech/chmlfrp`

## 用法

和 `frpc` 镜像完全一样，挂载自己的配置即可：

```bash
docker run -d --name frpc --restart unless-stopped \
  -v /path/to/frpc.toml:/etc/frp/frpc.toml:ro \
  ghcr.io/zetxtech/chmlfrp:latest
```

docker compose：

```yaml
services:
  frpc:
    image: ghcr.io/zetxtech/chmlfrp:latest
    restart: unless-stopped
    volumes:
      - ./frpc.toml:/etc/frp/frpc.toml:ro
```

想换配置文件位置时直接覆盖参数：

```bash
docker run --rm ghcr.io/zetxtech/chmlfrp:latest -c /etc/frp/other.toml
```

`frpc.toml` 就是 ChmlFrp 面板里给你的那份，例如：

```toml
serverAddr = "xxx.chmlfrp.net"
serverPort = 7000

auth.method = "token"
auth.token = "你在面板里看到的密钥"

[[proxies]]
name = "web"
type = "tcp"
localIP = "127.0.0.1"
localPort = 8080
remotePort = 12345
```

## 标签

| 标签 | 说明 |
| --- | --- |
| `latest`、`<version>`（如 `0.70.1_261019`） | 多架构 manifest，按宿主机自动选 |
| `0.70.1` | 去掉构建日期的版本号 |
| `<arch>`、`<version>-<arch>` | 单架构镜像，如 `amd64`、`0.70.1_261019-arm64` |

## 架构

| 上游 arch | OCI platform | 说明 |
| --- | --- | --- |
| amd64 | linux/amd64 | |
| arm | linux/arm/v7 | 上游是 GOARM=5 软浮点构建，armv5 及以上的 32 位 ARM 都能跑 |
| arm64 | linux/arm64 | |
| mips / mipsle | linux/mips、linux/mipsle | 路由器等设备 |
| mips64 / mips64le | linux/mips64、linux/mips64le | |
| riscv64 | linux/riscv64 | |

镜像基于 `scratch`，只包含静态链接的 `frpc` 和 CA 证书，没有 shell、没有包管理器。需要进容器排查时用 `docker run --entrypoint` 指定别的二进制是行不通的——这是刻意的：给 mips/riscv64 这类没有基础镜像的平台提供统一构建方式，同时不需要 qemu。

副作用：镜像内没有 tzdata，`TZ` 环境变量不生效，frpc 日志时间按 UTC 输出。

## 自动更新

`.github/workflows/build.yml`：

1. `meta` 任务请求 `https://cf-v2.uapis.cn/download_info`（面板下载页背后的接口），取出 `data.version`、`data.link` 和 `data.system.linux[]` 的每个架构及文件名。
2. `build` 任务按架构矩阵下载对应的 `tar.gz`，解出 `frpc`，用 `--platform` 构建单架构镜像并推到 GHCR。
3. `merge` 任务用 `docker buildx imagetools create` 把这些单架构镜像合成 `<version>`、`<version 去掉日期>`、`latest` 三个多架构标签。

触发方式：每天 03:17（UTC）定时检查、手动 `workflow_dispatch`、以及修改 `Dockerfile` 或工作流本身时。

上游发布新版本后，定时任务会生成新版本号标签；`latest` 始终跟随上游最新版。
