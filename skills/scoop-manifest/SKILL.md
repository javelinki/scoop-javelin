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

## 配置文件不放在 AppData（持久化/重定向）

### 目标
- 把软件把数据写到 `%APPDATA%` / `%LOCALAPPDATA%` 的内容重定向到 Scoop 的 `$persist_dir`，实现便携、升级不丢数据。
- 卸载时清理原始目录（可选）。

### 推荐做法（junction）
1. 在 `post_install` 中：
   - 计算 AppData 路径：`$datapath = Join-Path $env:AppData '<AppName>'`
   - 加载 helper：`. "$bucketsdir\<bucket>\scripts\Functions.ps1"`
   - 调用：`Move-Data_dir -data_dir $datapath -persist_dir $persist_dir`
2. 在 `pre_uninstall` 中：
   - `Remove-Item (Join-Path $env:AppData '<AppName>') -Recurse -Force -ErrorAction SilentlyContinue`
3. `persist` 字段列出需要持久化的子目录（如 `data`, `logs`）。

### helper 示例（scripts/Functions.ps1）
```powershell
function Move-Data_dir {
    param([string]$data_dir, [string]$persist_dir)
    if (Test-Path $data_dir) {
        if (Test-Path $persist_dir) {
            Get-ChildItem -Path $data_dir -Force | ForEach-Object {
                Move-Item -Path $_.FullName -Destination $persist_dir -Force
            }
            Remove-Item $data_dir -Recurse -Force -ErrorAction SilentlyContinue
        } else {
            Move-Item $data_dir $persist_dir
        }
    } elseif (-not (Test-Path $persist_dir)) {
        New-Item -ItemType Directory -Path $persist_dir | Out-Null
    }
    if (-not (Test-Path $data_dir)) {
        New-Item -ItemType Junction -Path $data_dir -Target $persist_dir | Out-Null
    }
}
```

### 注意事项
- junction 创建需要管理员权限？普通用户可创建 junction（directory junction），无需管理员。
- 如果 AppData 目录不存在，helper 会创建 persist_dir 并建立 junction。
- `pre_uninstall` 清理 junction 目标时要小心，只删 junction 本身（Remove-Item on junction 删除的是链接，不是目标）。
- 若软件支持 `--user-data-dir` 参数，优先用参数指定 `$persist_dir`，比 junction 更干净。

## 验证命令
```powershell
.\bin\checkurls.ps1
.\bin\checkhashes.ps1
powershell -ExecutionPolicy Bypass -File .\bin\test.ps1
```

## 参考
- Scoop 官方模板：`bucket/app-name.json.template`
- 本仓库 manifest 示例：`bucket/Serpent.json`、`bucket/IKUN-Music.json`
- 本仓库 helper：`scripts/Functions.ps1`
