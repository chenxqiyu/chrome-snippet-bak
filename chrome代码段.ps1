# 目标目录
$saveDir = "d:\chrome代码段"
# 文件路径
$filePath = "C:\Users\Administrator\AppData\Local\Google\Chrome\User Data\Default\Preferences"


# 如果目录不存在，则创建
if (-not (Test-Path -Path $saveDir)) {
    New-Item -Path $saveDir -ItemType Directory
}


# 流式读取文件
$reader = [System.IO.StreamReader]::new($filePath)
$found = $false
$jsonFragment = ""

while ($null -ne ($line = $reader.ReadLine())) {
    if ($line -match '"script-snippets":') {
        $found = $true
        $jsonFragment += $line
    }
    elseif ($found) {
        $jsonFragment += $line
        # 检查是否找到完整的 JSON 片段
        if ($jsonFragment -match '$$.*$$') {
            break
        }
    }
}
$reader.Close()

# 将 JSON 片段转换为 PowerShell 对象
try {
    $jsonObject = $jsonFragment | ConvertFrom-Json
    # 获取当前时间戳
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"

    # 构建保存路径
    $savePath = "$saveDir\script_$timestamp.json"
    $jsonObject.devtools.preferences.'script-snippets' | ConvertFrom-Json | ConvertTo-Json -Depth 10 | Out-File -FilePath $savePath

    $scriptSnippets = $jsonObject.devtools.preferences.'script-snippets' | ConvertFrom-Json

    # 遍历 JSON 数据
    foreach ($snippet in $scriptSnippets) {
        # 获取代码段名称和内容
        $name = $snippet.name
		
		$jsonString = $snippet.content -replace '\\d', '\\d'
        $content = [System.Text.RegularExpressions.Regex]::Unescape($jsonString)
		


        # 构建保存路径
        $savePath = Join-Path -Path $saveDir -ChildPath "$name.js"

        # 将内容保存到文件
        $content | Out-File -FilePath $savePath -Encoding UTF8

        Write-Output "已保存: $savePath"
    }
}
catch {
    Write-Output "无法将 JSON 片段转换为对象: $_"
}
pause
