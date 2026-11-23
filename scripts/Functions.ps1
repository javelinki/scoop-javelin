function Move-Data_dir {
    param(
        [string]$data_dir,
        [string]$persist_dir
    )
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
