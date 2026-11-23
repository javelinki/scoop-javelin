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

## 验证命令
```powershell
.\bin\checkurls.ps1
.\bin\checkhashes.ps1
powershell -ExecutionPolicy Bypass -File .\bin\test.ps1
```

## 参考
- Scoop 官方模板：`bucket/app-name.json.template`
- 本仓库 manifest 示例：`bucket/Serpent.json`、`bucket/IKUN-Music.json`
