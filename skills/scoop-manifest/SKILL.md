---
name: scoop-manifest
description: 'Use when creating or reviewing Scoop bucket manifests. Covers optimal field ordering, checkver/autoupdate patterns, hash handling, architecture consistency, and common pitfalls.'
---

# Scoop Manifest 最佳实践

## 适用场景
- 新增或修改 `bucket/*.json` manifest
- 检查 manifest 是否能通过 `scoop checkver` / CI
- 设计 `checkver` 与 `autoupdate` 自动更新链路

## 核心原则
1. **JSON 必须合法**：使用 4 空格缩进，字段顺序尽量与官方模板一致。
2. **homepage 与 checkver 匹配**：`checkver: "github"` 要求 `homepage` 为 GitHub 仓库 URL。
3. **autoupdate 必须带 hash**：每个架构都要有 `hash`（或全局 `hash`），否则更新时无法校验。
4. **架构一致性**：`64bit`/`32bit`/`arm64` 的 URL、hash、解包方式要一致；`#/dl.7z` 只在有 `pre_install` 解包脚本时使用。
5. **hash 格式**：支持 `sha256:...` 前缀或裸 64 位 hex；优先使用 `.sha256` 文件 + `regex: "$sha256"`。
6. **checkver 优先用 GitHub API**：避免依赖 HTML 页面结构，减少维护成本。

## 推荐字段顺序
```json
{
  "version": "",
  "description": "",
  "homepage": "",
  "license": "",
  "architecture": {
    "64bit": { "url": "", "hash": "" }
  },
  "shortcuts": [["exe", "name"]],
  "checkver": "github",
  "autoupdate": {
    "architecture": {
      "64bit": { "url": "", "hash": { "url": "", "regex": "$sha256" } }
    }
  }
}
```

## 常见陷阱
- `checkver: "github"` 但 homepage 不是 GitHub URL → Scoop 报错。
- `autoupdate` 缺少 `hash` → 更新时无法校验。
- `#/dl.7z` 与 `pre_install` 不匹配 → 安装失败。
- `checkver.url` 末尾多余 `/` → URL 无效。
- hash 与版本不对应 → 安装失败。

## 配置/数据持久化（Scoop 原生 persist）

### 目标
- 把软件把数据写到安装目录下的文件/文件夹持久化到 Scoop 的 persist 目录，升级/重装不丢数据。
- Scoop 原生支持 `persist` 字段，自动建立 junction/hardlink，**无需自定义脚本**。

### 用法
```json
"persist": [
    "data",
    "logs",
    ["config.ini", "config.ini"]
]
```
- 字符串：source=target，目录用 junction，文件用 hardlink。
- 数组：`[source, target]`，可把安装目录下的 `source` 映射到 persist 目录下的 `target`。
- `persist` 中的路径相对于安装目录 `$dir`。

### 注意事项
- `persist` 只持久化安装目录内的路径；软件写到 `%APPDATA%`/`%LOCALAPPDATA%` 的数据不会被 Scoop 自动持久化。
- 若软件支持 `--user-data-dir`/`--config` 等参数，优先用 `bin`/`shortcuts` 的 args 指定 `$persist_dir`，比 junction 更干净。
- 卸载时 Scoop 会自动 `unlink_persist_data`，无需 `pre_uninstall` 手动清理（除非用了 junction helper）。
- 若必须重定向 AppData，才考虑 `post_install` junction helper，但这不是 Scoop 原生方式，维护成本高。

## 验证命令
```powershell
.\bin\checkurls.ps1
.\bin\checkhashes.ps1
powershell -ExecutionPolicy Bypass -File .\bin\test.ps1
```

## 参考
- Scoop 官方模板：`bucket/app-name.json.template`
- 本仓库 manifest 示例：`bucket/Serpent.json`、`bucket/IKUN-Music.json`
- Scoop 源码：`lib/install.ps1`（persist_data / unlink_persist_data）
