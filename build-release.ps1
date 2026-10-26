param(
    [Parameter(Mandatory = $true)]
    [string]$Python,

    [string]$Version = "3.0.0"
)

$ErrorActionPreference = "Stop"

$projectRoot = $PSScriptRoot
$sourceRoot = Join-Path $projectRoot "src"
$toolRoot = Join-Path $projectRoot "tools"
$buildRoot = Join-Path $projectRoot "tmp\pyinstaller"
$releaseRoot = Join-Path $projectRoot "deliverables\ImageChange-$Version"
$executable = Join-Path $releaseRoot "ImageChange.exe"

if (-not (Test-Path (Join-Path $toolRoot "realesrgan-ncnn-vulkan\realesrgan-ncnn-vulkan.exe"))) {
    throw "缺少离线超分辨率引擎：$toolRoot"
}

if (Test-Path $releaseRoot) {
    throw "发布目录已存在，为避免覆盖交付物已停止：$releaseRoot"
}

New-Item -ItemType Directory -Force -Path $buildRoot | Out-Null

& $Python -m PyInstaller `
    --noconfirm `
    --clean `
    --onefile `
    --windowed `
    --name ImageChange `
    --icon (Join-Path $sourceRoot "assets\logo.ico") `
    --version-file (Join-Path $sourceRoot "version_info.txt") `
    --add-data "$(Join-Path $sourceRoot 'assets');assets" `
    --hidden-import pypdfium2 `
    --collect-all pypdfium2 `
    --collect-all pypdfium2_raw `
    --distpath (Join-Path $buildRoot "dist") `
    --workpath (Join-Path $buildRoot "work") `
    --specpath (Join-Path $buildRoot "spec") `
    (Join-Path $sourceRoot "app.py")

if ($LASTEXITCODE -ne 0) {
    throw "ImageChange 打包失败"
}

New-Item -ItemType Directory -Path $releaseRoot | Out-Null
Copy-Item -LiteralPath (Join-Path $buildRoot "dist\ImageChange.exe") -Destination $executable
Copy-Item -LiteralPath $toolRoot -Destination (Join-Path $releaseRoot "tools") -Recurse
Copy-Item -LiteralPath (Join-Path $projectRoot "docs\交付说明-$Version.md") -Destination (Join-Path $releaseRoot "使用说明.md")

Get-FileHash -Algorithm SHA256 $executable |
    ForEach-Object { "{0}  ImageChange.exe" -f $_.Hash } |
    Set-Content -Encoding ASCII (Join-Path $releaseRoot "SHA256.txt")

Write-Host "发布包已创建：$releaseRoot"
