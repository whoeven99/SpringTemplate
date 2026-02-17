# SpringTemplate 服务生成脚本
# 功能：根据用户输入的服务名，复制项目并替换所有SpringTemplate相关名称

param(
    [Parameter(Mandatory=$false)]
    [string]$ServiceName
)

# 如果未通过参数传入，则提示用户输入
if (-not $ServiceName) {
    $ServiceName = Read-Host "请输入服务名称（例如：gordon）"
}

# 验证输入
if ([string]::IsNullOrWhiteSpace($ServiceName)) {
    Write-Host "错误：服务名称不能为空！" -ForegroundColor Red
    exit 1
}

# 验证服务名格式（只允许字母、数字、连字符和下划线）
if ($ServiceName -notmatch '^[a-zA-Z0-9_-]+$') {
    Write-Host "错误：服务名称只能包含字母、数字、连字符和下划线！" -ForegroundColor Red
    exit 1
}

# 获取脚本所在目录（项目根目录）
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$SourceDir = $ScriptDir
$TargetDir = Join-Path $ScriptDir $ServiceName

# 检查目标目录是否已存在
if (Test-Path $TargetDir) {
    $overwrite = Read-Host "目标目录 '$ServiceName' 已存在，是否覆盖？(y/n)"
    if ($overwrite -ne 'y' -and $overwrite -ne 'Y') {
        Write-Host "操作已取消。" -ForegroundColor Yellow
        exit 0
    }
    Remove-Item $TargetDir -Recurse -Force
}

Write-Host "`n开始生成服务：$ServiceName" -ForegroundColor Green
Write-Host "源目录：$SourceDir" -ForegroundColor Cyan
Write-Host "目标目录：$TargetDir" -ForegroundColor Cyan

# 准备服务名的各种变体
$ServiceNameLower = $ServiceName.ToLower()
$ServiceNameUpper = $ServiceName.ToUpper()

# 判断是否已经是驼峰命名（包含大写字母，且不是全大写）
# 如果是驼峰命名，保持原样；否则转换为首字母大写格式
if ($ServiceName -cmatch '[A-Z]' -and $ServiceName -cne $ServiceNameUpper) {
    # 已经是驼峰命名，保持原样
    $ServiceNameCapitalized = $ServiceName
} else {
    # 转换为首字母大写格式
    $ServiceNameCapitalized = $ServiceName.Substring(0,1).ToUpper() + $ServiceName.Substring(1).ToLower()
}

# 步骤1：复制项目文件（排除target、.git等目录）
Write-Host "`n步骤1：复制项目文件..." -ForegroundColor Yellow

# 创建目标目录
if (-not (Test-Path $TargetDir)) {
    New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null
}

# 使用robocopy进行复制，排除不需要的目录
# robocopy参数：源目录 目标目录 /E(包含子目录) /XD(排除目录) /XF(排除文件) /NFL(不显示文件列表) /NDL(不显示目录列表) /NJH(不显示作业头) /NJS(不显示作业摘要)
& robocopy $SourceDir $TargetDir /E /XD target .git .idea $ServiceName /XF generate-service.ps1 generate-service.bat /NFL /NDL /NJH /NJS | Out-Null

# robocopy返回码：0-7都是正常的（0=无变化，1=文件已复制，等等），8及以上表示错误
$robocopyExitCode = $LASTEXITCODE
if ($robocopyExitCode -ge 8) {
    Write-Host "警告：复制过程中可能存在问题（退出码：$robocopyExitCode）" -ForegroundColor Yellow
} else {
    Write-Host "文件复制完成！" -ForegroundColor Green
}

# 步骤2：替换文件内容中的SpringTemplate
Write-Host "`n步骤2：替换文件内容..." -ForegroundColor Yellow

# 定义替换规则（按长度从长到短排序，避免部分匹配问题）
$replacements = @(
    @{ Pattern = 'SpringTemplateUser'; Replacement = "$ServiceNameCapitalized" + "User" },
    @{ Pattern = 'SpringTemplateIntegration'; Replacement = "$ServiceNameCapitalized" + "Integration" },
    @{ Pattern = 'SpringTemplateRepository'; Replacement = "$ServiceNameCapitalized" + "Repository" },
    @{ Pattern = 'SpringTemplateService'; Replacement = "$ServiceNameCapitalized" + "Service" },
    @{ Pattern = 'SpringTemplateCommon'; Replacement = "$ServiceNameCapitalized" + "Common" },
    @{ Pattern = 'SpringTemplateApi'; Replacement = "$ServiceNameCapitalized" + "Api" },
    @{ Pattern = 'SPRINGTEMPLATE'; Replacement = $ServiceNameLower },
    @{ Pattern = 'SpringTemplate'; Replacement = $ServiceNameCapitalized },
    @{ Pattern = 'springtemplate'; Replacement = $ServiceNameLower }
)

# 获取所有需要处理的文件（排除二进制文件）
$textExtensions = @('.java', '.xml', '.yml', '.yaml', '.properties', '.md', '.txt', '.ddl', '.sql', '.json', '.gradle', '.sh', '.bat', '.ps1')
$filesToProcess = Get-ChildItem -Path $TargetDir -Recurse -File | Where-Object {
    $ext = [System.IO.Path]::GetExtension($_.Name).ToLower()
    $textExtensions -contains $ext -or $ext -eq ''
}

$totalFiles = $filesToProcess.Count
$processedFiles = 0

foreach ($file in $filesToProcess) {
    try {
        # 使用 System.IO.File 读取文件，自动处理 BOM
        $content = [System.IO.File]::ReadAllText($file.FullName, [System.Text.Encoding]::UTF8)
        if ($null -eq $content) {
            continue
        }
        
        $originalContent = $content
        $modified = $false
        
        # 执行所有替换（按顺序，从长到短）
        foreach ($replacement in $replacements) {
            if ($content -match [regex]::Escape($replacement.Pattern)) {
                $content = $content -replace [regex]::Escape($replacement.Pattern), $replacement.Replacement
                $modified = $true
            }
        }
        
        # 如果内容被修改，使用不带 BOM 的 UTF-8 编码写回文件
        if ($modified) {
            $utf8NoBom = New-Object System.Text.UTF8Encoding $false
            [System.IO.File]::WriteAllText($file.FullName, $content, $utf8NoBom)
            $processedFiles++
        }
    } catch {
        Write-Host "警告：无法处理文件 $($file.FullName): $_" -ForegroundColor Yellow
    }
}

Write-Host "已处理 $processedFiles 个文件的内容替换！" -ForegroundColor Green

# 步骤3：重命名文件夹和文件
Write-Host "`n步骤3：重命名文件夹和文件..." -ForegroundColor Yellow

# 重命名模块文件夹
$moduleFolders = @(
    @{ Old = "SpringTemplateApi"; New = "$ServiceNameCapitalized" + "Api" },
    @{ Old = "SpringTemplateService"; New = "$ServiceNameCapitalized" + "Service" },
    @{ Old = "SpringTemplateIntegration"; New = "$ServiceNameCapitalized" + "Integration" },
    @{ Old = "SpringTemplateRepository"; New = "$ServiceNameCapitalized" + "Repository" },
    @{ Old = "SpringTemplateCommon"; New = "$ServiceNameCapitalized" + "Common" }
)

foreach ($module in $moduleFolders) {
    $oldPath = Join-Path $TargetDir $module.Old
    $newPath = Join-Path $TargetDir $module.New
    
    if (Test-Path $oldPath) {
        Rename-Item -Path $oldPath -NewName $module.New -Force
        Write-Host "  重命名文件夹: $($module.Old) -> $($module.New)" -ForegroundColor Cyan
    }
}

# 重命名包目录（com/springtemplate -> com/$ServiceNameLower）
$packageBasePath = Join-Path $TargetDir "com\springtemplate"
$newPackageBasePath = Join-Path $TargetDir "com\$ServiceNameLower"

# 查找所有包含springtemplate的包目录
Get-ChildItem -Path $TargetDir -Recurse -Directory | Where-Object {
    $_.Name -eq "springtemplate"
} | ForEach-Object {
    $parentDir = $_.Parent.FullName
    $newPath = Join-Path $parentDir $ServiceNameLower
    if (-not (Test-Path $newPath)) {
        Rename-Item -Path $_.FullName -NewName $ServiceNameLower -Force
        Write-Host "  重命名包目录: springtemplate -> $ServiceNameLower" -ForegroundColor Cyan
    }
}

# 重命名.iml文件
Get-ChildItem -Path $TargetDir -Recurse -Filter "*.iml" | ForEach-Object {
    $newName = $_.Name -replace 'SpringTemplate', $ServiceNameCapitalized
    if ($newName -ne $_.Name) {
        Rename-Item -Path $_.FullName -NewName $newName -Force
        Write-Host "  重命名文件: $($_.Name) -> $newName" -ForegroundColor Cyan
    }
}

Write-Host "`n服务生成完成！" -ForegroundColor Green
Write-Host "新服务目录：$TargetDir" -ForegroundColor Cyan
Write-Host "`n下一步操作：" -ForegroundColor Yellow
Write-Host "1. 进入新服务目录：cd $ServiceName" -ForegroundColor White
Write-Host "2. 检查并更新配置文件" -ForegroundColor White
Write-Host "3. 运行 mvn clean install 构建项目" -ForegroundColor White
