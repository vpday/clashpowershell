$ClashReleaseObject = $null
$ConsoleConfig = $null
$UnixTime1970 = Get-Date -Date "01/01/1970"
$CurrentPath = (Get-Location).Path
$ConsoleConfigPath = $CurrentPath + "\App\cps\config.json"
$ClashFolderPath = $CurrentPath + "\App\clash"
$ClashExePath = $ClashFolderPath + "\clash-core.exe"
$ClashProfilePath = $CurrentPath + "\Profile"
$ClashConfigPath = $CurrentPath + "\Profile\config.yaml"
$WebDashboardPath = $ClashProfilePath + "\web-dashboard"
$GeoIPDbPath = $ClashProfilePath + "\Country.mmdb"
$SysProxyExePath = $CurrentPath + "\App\sysproxy.exe"
$LocaleMessage = Import-LocalizedData -BaseDirectory (Join-Path -Path $PSScriptRoot -ChildPath Locale)

function Load-Config {
    Write-Host ""
    Write-Host $LocaleMessage.ConsoleConfigLoading

    $script:ConsoleConfig = Get-Content -Path $ConsoleConfigPath | ConvertFrom-Json

    Add-Member -InputObject $ConsoleConfig -Name ClashPremium -Value $false -MemberType NoteProperty
    Add-Member -InputObject $ConsoleConfig -Name ClashVersion -Value "" -MemberType NoteProperty

    if (!$ConsoleConfig.ClashCheckPeriod) {
        Add-Member -InputObject $ClashCheckPeriod -Name ClashLastCheck -Value 0 -MemberType NoteProperty
    }

    if (($ConsoleConfig.ClashCheckPeriod -gt 0) -and ((!$ConsoleConfig.ClashLastCheck) -or ($ConsoleConfig.ClashLastCheck -le 0)) -and (Test-Path $ClashExePath)) {
        $lastWriteTime = (Get-Item $ClashExePath).LastWriteTime
        $clashLastCheck = ($lastWriteTime - $UnixTime1970).TotalMilliseconds

        if (!$ConsoleConfig.ClashLastCheck) {
            Add-Member -InputObject $ConsoleConfig -Name ClashLastCheck -Value $clashLastCheck -MemberType NoteProperty
        }
        else {
            $ConsoleConfig.ClashLastCheck = $clashLastCheck
        }
    }

    $webDashboardSupported = "razord", "yacd"
    if (!$ConsoleConfig.WebDashboardType) {
        Add-Member -InputObject $ConsoleConfig -Name WebDashboardType -Value $webDashboardSupported[0] -MemberType NoteProperty
    }
    elseif (($webDashboardSupported[0] -ne $ConsoleConfig.WebDashboardType) -and ($webDashboardSupported[1] -ne $ConsoleConfig.WebDashboardType)) {
        $ConsoleConfig.WebDashboardType = $webDashboardSupported[0]
    }

    $webDashboardDownloadUrl = ""
    if ($ConsoleConfig.GitHubProxyUrl) {
        $webDashboardDownloadUrl += $ConsoleConfig.GitHubProxyUrl + "/"
    }
    if ($webDashboardSupported[0] -eq $ConsoleConfig.WebDashboardType) {
        $webDashboardDownloadUrl += "https://github.com/Dreamacro/clash-dashboard/archive/gh-pages.zip"
    }
    elseif ($webDashboardSupported[1] -eq $ConsoleConfig.WebDashboardType) {
        $webDashboardDownloadUrl += "https://github.com/haishanh/yacd/archive/gh-pages.zip"
    }
    Add-Member -InputObject $ConsoleConfig -Name WebDashboardDownloadUrl -Value $webDashboardDownloadUrl -MemberType NoteProperty

    if (!$ConsoleConfig.WebDashboardCheckPeriod) {
        Add-Member -InputObject $ConsoleConfig -Name WebDashboardCheckPeriod -Value 0 -MemberType NoteProperty
    }

    if (($ConsoleConfig.WebDashboardCheckPeriod -gt 0) -and ((!$ConsoleConfig.WebDashboardLastCheck) -or ($ConsoleConfig.WebDashboardLastCheck -le 0)) -and (Test-Path $WebDashboardPath)) {
        $lastWriteTime = (Get-Item $WebDashboardPath).LastWriteTime
        $webDashboardLastCheck = ($lastWriteTime - $UnixTime1970).TotalMilliseconds
        if (!$ConsoleConfig.WebDashboardLastCheck) {
            Add-Member -InputObject $ConsoleConfig -Name WebDashboardLastCheck -Value $webDashboardLastCheck -MemberType NoteProperty
        }
        else {
            $ConsoleConfig.WebDashboardLastCheck = $webDashboardLastCheck
        }
    }

    if (!$ConsoleConfig.GeoIPDbDownloadUrl) {
        $geoIPDbDownloadUrl = ""
        if ($ConsoleConfig.GitHubProxyUrl) {
            $geoIPDbDownloadUrl += $ConsoleConfig.GitHubProxyUrl + "/"
        }
        $geoIPDbDownloadUrl += "https://github.com/Dreamacro/maxmind-geoip/releases/latest/download/Country.mmdb"
        Add-Member -InputObject $ConsoleConfig -Name GeoIPDbDownloadUrl -Value $geoIPDbDownloadUrl -MemberType NoteProperty
    }

    if (!$ConsoleConfig.GeoIPDbCheckPeriod) {
        Add-Member -InputObject $ConsoleConfig -Name GeoIPDbCheckPeriod -Value 0 -MemberType NoteProperty
    }

    if (($ConsoleConfig.GeoIPDbCheckPeriod -gt 0) -and ((!$ConsoleConfig.GeoIPDbLastCheck) -or ($ConsoleConfig.GeoIPDbLastCheck -le 0)) -and (Test-Path $GeoIPDbPath)) {
        $lastWriteTime = (Get-Item $GeoIPDbPath).LastWriteTime
        $geoIPDbLastCheck = ($lastWriteTime - $UnixTime1970).TotalMilliseconds
        if (!$ConsoleConfig.GeoIPDbLastCheck) {
            Add-Member -InputObject $ConsoleConfig -Name GeoIPDbLastCheck -Value $geoIPDbLastCheck -MemberType NoteProperty
        }
        else {
            $ConsoleConfig.GeoIPDbLastCheck = $geoIPDbLastCheck
        }
    }

    if (!$ConsoleConfig.IPQueryUrl) {
        Add-Member -InputObject $ConsoleConfig -Name IPQueryUrl -Value "https://myip.ipip.net" -MemberType NoteProperty
    }

    if (!$ConsoleConfig.SysProxyBypass) {
        Add-Member -InputObject $ConsoleConfig -Name SysProxyBypass -Value "localhost;0.0.0.0;127.*;10.*;100.64.*;192.168.*;<local>" -MemberType NoteProperty
    }

    if (!$ConsoleConfig.SysProxyServer) {
        throw $LocaleMessage.SysProxyServerNotConfig
    }

    Write-Host $LocaleMessage.ConsoleConfigLoaded
    Start-Sleep -Milliseconds 500
}

function Out-Config {
    if ($ConsoleConfig -and $ConsoleConfigPath) {
        $consoleConfigCopy = New-Object PsObject
        foreach ($item in $ConsoleConfig.psobject.properties) {
            if (("WebDashboardDownloadUrl" -ne $item.Name) -and ("ClashPremium" -ne $item.Name) -and ("ClashVersion" -ne $item.Name)) {
                Add-Member -InputObject $consoleConfigCopy -MemberType $item.MemberType -Name $item.Name -Value $item.Value
            }
        }

        $consoleConfigJson = ConvertTo-Json -InputObject $consoleConfigCopy -Depth 100
        $replaceChars = @{
            "\\u003c" = "<"
            "\\u003e" = ">"
            "\\u0027" = "'"
            "\\u0026" = "&"
        }
        foreach ($char in $replaceChars.GetEnumerator()) {
            $consoleConfigJson = $consoleConfigJson -replace $char.Key, $char.Value
        }

        Out-File -InputObject $consoleConfigJson -FilePath $ConsoleConfigPath -Encoding UTF8
    }
}

function Check-File {
    Write-Host ""
    Write-Host $LocaleMessage.ConsoleFileChecking

    $Host.UI.RawUI.WindowTitle = $LocaleMessage.ConsoleTitle

    if (!(Test-Path $ConsoleConfigPath)) {
        throw $LocaleMessage.ConsoleConfigNotFound
    }

    if (!(Test-Path $SysProxyExePath)) {
        throw $LocaleMessage.SysProxyNotFound
    }

    if (!(Test-Path $ClashConfigPath)) {
        throw $LocaleMessage.ClashConfigNotFound
    }

    if (!(Test-Path $ClashExePath)) {
        Write-Host ""
        Write-Host $LocaleMessage.ClashNotFound -ForegroundColor Red
        Update-Clash
        $ConsoleConfig.ClashLastCheck = ($(Get-Date) - $UnixTime1970).TotalMilliseconds
    }

    if (!(Test-Path $WebDashboardPath)) {
        Write-Host ""
        Write-Host $LocaleMessage.WebDashboardNotFound -ForegroundColor Red
        Update-WebDashboard
        $ConsoleConfig.WebDashboardLastCheck = ($(Get-Date) - $UnixTime1970).TotalMilliseconds
    }

    if (!(Test-Path $GeoIPDbPath)) {
        Write-Host ""
        Write-Host $LocaleMessage.GeoIPDbNotFound -ForegroundColor Red
        Update-GeoIPDb
        $ConsoleConfig.GeoIPDbLastCheck = ($(Get-Date) - $UnixTime1970).TotalMilliseconds
    }

    Write-Host $LocaleMessage.ConsoleFileChecked
    Start-Sleep -Milliseconds 500
}

function Check-Update {
    Write-Host ""
    Write-Host $LocaleMessage.ConsoleUpdateChecking

    $currentDateTime = Get-Date
    $currentUnixTime = ($currentDateTime - $UnixTime1970).TotalMilliseconds

    if ($ConsoleConfig.ClashCheckPeriod -gt 0) {
        $clashLastCheck = $UnixTime1970.AddMilliseconds($ConsoleConfig.ClashLastCheck).AddDays($ConsoleConfig.ClashCheckPeriod)
        if ($currentDateTime.CompareTo($clashLastCheck) -ge 0) {
            $script:ClashReleaseObject = Get-ClashRelease
            if ($ClashReleaseObject.name -ne $ConsoleConfig.ClashVersion) {
                Update-Clash
                Load-ClashVersion
            }
            $ConsoleConfig.ClashLastCheck = $currentUnixTime
        }
    }

    if ($ConsoleConfig.WebDashboardCheckPeriod -gt 0) {
        $webDashboardLastCheck = $UnixTime1970.AddMilliseconds($ConsoleConfig.WebDashboardLastCheck).AddDays($ConsoleConfig.WebDashboardCheckPeriod)
        if ($currentDateTime.CompareTo($webDashboardLastCheck) -ge 0) {
            Update-WebDashboard
            $ConsoleConfig.WebDashboardLastCheck = $currentUnixTime
        }
    }

    if ($ConsoleConfig.GeoIPDbCheckPeriod -gt 0) {
        $geoIPDbLastCheck = $UnixTime1970.AddMilliseconds($ConsoleConfig.GeoIPDbLastCheck).AddDays($ConsoleConfig.GeoIPDbCheckPeriod)
        if ($currentDateTime.CompareTo($geoIPDbLastCheck) -ge 0) {
            Update-GeoIPDb
            $ConsoleConfig.GeoIPDbLastCheck = $currentUnixTime
        }
    }

    Write-Host $LocaleMessage.ConsoleUpdateChecked
    Start-Sleep -Milliseconds 500
}

function Make-MainMenu {
    $statusText = $LocaleMessage.ClashStopped
    if (Get-ApplicationStatus) {
        $statusText = $LocaleMessage.ClashRuning
    }

    Clear-Host
    Write-Host "-------------------------------------"
    Write-Host ""
    Write-Host "  Clash $($ConsoleConfig.ClashVersion) $statusText"
    Write-Host ""
    Write-Host "  $($LocaleMessage.MenuChoice)"

    for ($i = 0; $i -lt $LocaleMessage.MenuOptions.Count; $i++) {
        Write-Host ""
        Write-Host "  [$($LocaleMessage.MenuSelections[$i])] $($LocaleMessage.MenuOptions[$i])"
    }

    Write-Host ""
    Write-Host "-------------------------------------"

    Switch-Operation
}

function Switch-Operation {
    Write-Host ""
    $selection = Read-Host -Prompt "$($LocaleMessage.MenuSelect) [$($LocaleMessage.MenuSelections -join(','))]"

    Switch ($selection) {
        "R" {
            Start-Applications
            Enable-Proxy
            Break
        }
        "S" {
            Stop-Applications
            Disable-Proxy
            Break
        }
        "D" {
            Open-WebDashboard
            Break
        }
        "T" {
            Test-ClashConfiguration
            Start-SleepAndWrite 4 $LocaleMessage.MenuReturn
            Break
        }
        "C" {
            Update-Clash
            $ConsoleConfig.ClashLastCheck = ($(Get-Date) - $UnixTime1970).TotalMilliseconds
            Out-Config
            Break
        }
        "G" {
            Update-GeoIPDb
            $ConsoleConfig.WebDashboardLastCheck = ($(Get-Date) - $UnixTime1970).TotalMilliseconds
            Out-Config
            Break
        }
        "W" {
            Update-WebDashboard
            $ConsoleConfig.GeoIPDbLastCheck = ($(Get-Date) - $UnixTime1970).TotalMilliseconds
            Out-Config
            Break
        }
        "I" {
            Show-LocalIpInfo
            Start-SleepAndWrite 4 $LocaleMessage.MenuReturn
            Break
        }
        "X" {
            Write-Host ""
            Write-Host $LocaleMessage.ConsoleShutdown
            exit 1
        }
        Default {
            Write-Host "$($LocaleMessage.ConsoleInputError)$selection" -ForegroundColor Red
            Switch-Operation
            Break
        }
    }

    Make-MainMenu
}

function Get-ApplicationStatus {
    $clashObject = Get-Clash
    return $null -ne $clashObject
}

function Start-Applications {
    Start-Clash
}

function Stop-Applications {
    Stop-Clash
}

function Get-Clash {
    Write-Host ""
    Write-Host $LocaleMessage.ClashGettingStatus
    return Get-Application "clash-core"
}

function Start-Clash {
    Write-Host ""
    Write-Host $LocaleMessage.ClashStarting
    Start-Process -FilePath $ClashExePath -ArgumentList "-d $ClashProfilePath" -WindowStyle Hidden
    Write-Host $LocaleMessage.ClashStarted
    Start-Sleep -Milliseconds 500
}

function Stop-Clash {
    $clashObject = Get-Clash
    if ($clashObject) {
        Write-Host ""
        Write-Host $LocaleMessage.ClashTerminating
        Stop-Application $clashObject
        Write-Host $LocaleMessage.ClashTerminated
        Start-Sleep -Milliseconds 500
    }
    else {
        Write-Host ""
        Write-Warning $LocaleMessage.ClashAlreadyStopped
    }
}

function Get-Application([string]$name) {
    $processObject = Get-Process -Name $name -ErrorAction "SilentlyContinue"
    if (!$?) {
        $processObject = $null
    }
    return $processObject
}

function Stop-Application($inputObject) {
    Stop-Process -InputObject $inputObject -Force
}

function Enable-Proxy {
    Write-Host ""
    Write-Host $LocaleMessage.SysProxyEnabling
    Set-IEProxy $true
    Write-Host $LocaleMessage.SysProxyEnabled
    Start-Sleep -Milliseconds 1000
}

function Disable-Proxy {
    Write-Host ""
    Write-Host $LocaleMessage.SysProxyDisabling
    Set-IEProxy $false
    Write-Host $LocaleMessage.SysProxyDisabled
    Start-Sleep -Milliseconds 1000
}

function Set-IEProxy([bool]$enable = $false) {
    if ($enable) {
        Start-Process -FilePath $SysProxyExePath -ArgumentList "global $($ConsoleConfig.SysProxyServer) $($ConsoleConfig.SysProxyBypass)" -WindowStyle Hidden -Wait
    }
    else {
        Start-Process -FilePath $SysProxyExePath -ArgumentList "set 1" -WindowStyle Hidden -Wait
    }
}

function Open-WebDashboard {
    if ($ConsoleConfig.ClashControllerUrl) {
        Start-Process -FilePath $($ConsoleConfig.ClashControllerUrl + "/ui")
    }
    else {
        Write-Host ""
        Start-SleepAndWrite 4 $LocaleMessage.ClashControllerUrlNotFound Red
    }
}

function Show-LocalIpInfo {
    Write-Host ""
    Write-Host $LocaleMessage.IPQuerying
    $localIpInfo = Invoke-RestMethod -Uri $ConsoleConfig.IPQueryUrl
    Write-Host $localIpInfo
}

function Update-Clash {
    if (!$ClashReleaseObject) {
        $script:ClashReleaseObject = Get-ClashRelease
    }
    if (!$ClashReleaseObject) {
        Write-Host ""
        Start-SleepAndWrite 4 $LocaleMessage.ClashReleaseNotFound Red
        return
    }

    $windowsAssets = @()
    foreach ($asset in $ClashReleaseObject.assets) {
        if ($asset.name.StartsWith("clash-windows")) {
            $windowsAssets += @{
                name                 = $asset.name;
                browser_download_url = $asset.browser_download_url
            }
        }
    }

    $selection = -1
    do {
        Write-Host ""
        Write-Host $LocaleMessage.ClashUpdateFileChoice
        $selectIndex = @()
        for ($i = 0; $i -lt $windowsAssets.Count; $i++) {
            $selectIndex += $i
            Write-Host "[$i] $($windowsAssets[$i].name)"
        }

        $inputText = Read-Host -Prompt "$($LocaleMessage.MenuSelect) [$($selectIndex -join(','))]"
        $inputValid = [int]::TryParse($inputText, [ref]$selection)
        if ((-not $inputValid) -or ($selection -ge $windowsAssets.Count)) {
            Write-Host "$($LocaleMessage.ConsoleInputError)$inputText" -ForegroundColor Red
        }
    } while ((-not $inputValid) -or ($selection -ge $windowsAssets.Count))

    $asset = $windowsAssets[$selection]
    $zipFileName = $asset.name

    Write-Host ""
    Write-Host "$($LocaleMessage.ClashDownloading) $zipFileName"
    $downloadUrl = ""
    if ($ConsoleConfig.GitHubProxyUrl) {
        $downloadUrl += $ConsoleConfig.GitHubProxyUrl + "/"
    }
    $downloadUrl += $asset.browser_download_url
    Invoke-WebRequest -Uri $downloadUrl -UserAgent [Microsoft.PowerShell.Commands.PSUserAgent]::FireFox -OutFile $zipFileName

    $clashObject = Get-Clash
    if ($clashObject) {
        Disable-Proxy
        Stop-Clash
    }

    Write-Host "$($LocaleMessage.ClashDecompressing) $zipFileName"
    Expand-Archive -LiteralPath $($CurrentPath + "\" + $zipFileName) -DestinationPath $ClashFolderPath -Force

    Write-Host $LocaleMessage.ClashMoving
    Move-Item -Path $($ClashFolderPath + "\clash-windows-*.exe") -Destination $ClashExePath -Force

    if (Test-Path $zipFileName) {
        Remove-Item $zipFileName
    }

    Write-Host $LocaleMessage.ClashUpdated
    Start-Sleep -Milliseconds 500

    if ($clashObject) {
        Start-Clash
        Enable-Proxy
    }
}

function Update-WebDashboard {
    Write-Host ""
    Write-Host $LocaleMessage.WebDashboardDownloading

    $packageFileName = "web-dashboard.zip"
    $packageFilePath = $CurrentPath + "\" + $packageFileName
    Invoke-WebRequest -Uri $ConsoleConfig.WebDashboardDownloadUrl -UserAgent [Microsoft.PowerShell.Commands.PSUserAgent]::FireFox -OutFile $packageFileName

    Write-Host $LocaleMessage.WebDashboardDecompressing
    Expand-Archive -LiteralPath $packageFilePath -DestinationPath $ClashProfilePath -Force

    Write-Host $LocaleMessage.WebDashboardMoving
    Get-Item -Path $WebDashboardPath -ErrorAction "SilentlyContinue" | Remove-Item -Recurse
    Move-Item -Path $($ClashProfilePath + "\*-gh-pages") -Destination $WebDashboardPath

    if (Test-Path $packageFilePath) {
        Remove-Item $packageFilePath
    }

    Write-Host $LocaleMessage.WebDashboardUpdated
    Start-Sleep -Milliseconds 500
}

function Update-GeoIPDb {
    Write-Host ""
    Write-Host $LocaleMessage.GeoIPDbDownloading
    $fileName = "Country.mmdb"
    Invoke-WebRequest -Uri $ConsoleConfig.GeoIPDbDownloadUrl -UserAgent [Microsoft.PowerShell.Commands.PSUserAgent]::FireFox -OutFile $fileName

    $clashObject = Get-Clash
    if ($clashObject) {
        Disable-Proxy
        Stop-Clash
    }

    Write-Host $LocaleMessage.GeoIPDbMoving
    Move-Item -Path $($CurrentPath + "\" + $fileName) -Destination $GeoIPDbPath -Force

    Write-Host $LocaleMessage.GeoIPDbUpdated
    Start-Sleep -Milliseconds 500

    if ($clashObject) {
        Start-Clash
        Enable-Proxy
    }
}

function Get-ClashRelease {
    Write-Host ""
    Write-Host $LocaleMessage.ClashGettingRelease

    $headers = @{
        'Accept' = 'application/vnd.github.v3+json'
    }
    $link = "https://api.github.com/repos/Dreamacro/clash/releases"
    if ($ConsoleConfig.ClashPremium) {
        $link += "/tags/premium"
    }
    else {
        $link += "/latest"
    }

    $clashReleaseObject = Invoke-RestMethod -Uri $link -Headers $headers -UserAgent [Microsoft.PowerShell.Commands.PSUserAgent]::FireFox
    if (!$?) {
        $clashReleaseObject = $null
    }

    return $clashReleaseObject
}

function Load-ClashVersion {
    Write-Host ""
    Write-Host $LocaleMessage.ClashGettingVersion

    $clashStartInfo = New-Object System.Diagnostics.ProcessStartInfo
    $clashStartInfo.FileName = $ClashExePath
    $clashStartInfo.Arguments = "-v"
    $clashStartInfo.UseShellExecute = $false
    $clashStartInfo.RedirectStandardError = $true
    $clashStartInfo.RedirectStandardOutput = $true
    $UTF8Encoding = New-Object System.Text.UTF8Encoding
    $clashStartInfo.StandardErrorEncoding = $UTF8Encoding
    $clashStartInfo.StandardOutputEncoding = $UTF8Encoding

    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $clashStartInfo
    $process.Start() | Out-Null
    $process.WaitForExit() | Out-Null

    if (0 -eq $process.ExitCode) {
        $clashVersionStr = $process.StandardOutput.ReadToEnd().Split(" ")[1]
        $ConsoleConfig.ClashPremium = !($clashVersionStr.IndexOf("v") -eq 0)
        if ($ConsoleConfig.ClashPremium) {
            $ConsoleConfig.ClashVersion = "Premium "
        }
        $ConsoleConfig.ClashVersion += $clashVersionStr
    }
    else {
        Write-Host ""
        Start-SleepAndWrite 4 $process.StandardError.ReadToEnd() Red
    }
}

function Test-ClashConfiguration {
    Write-Host ""
    Write-Host $LocaleMessage.ClashTestingConfig

    $clashStartInfo = New-Object System.Diagnostics.ProcessStartInfo
    $clashStartInfo.FileName = $ClashExePath
    $clashStartInfo.Arguments = "-d $ClashProfilePath -t"
    $clashStartInfo.UseShellExecute = $false
    $clashStartInfo.RedirectStandardError = $true
    $clashStartInfo.RedirectStandardOutput = $true
    $UTF8Encoding = New-Object System.Text.UTF8Encoding
    $clashStartInfo.StandardErrorEncoding = $UTF8Encoding
    $clashStartInfo.StandardOutputEncoding = $UTF8Encoding

    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $clashStartInfo
    $process.Start() | Out-Null
    $process.WaitForExit() | Out-Null

    if (0 -eq $process.ExitCode) {
        Write-Host ""
        Write-Host $process.StandardOutput.ReadToEnd()
    }
    else {
        Write-Host ""
        Start-SleepAndWrite 4 $process.StandardError.ReadToEnd() Red
    }
}

function Start-SleepAndWrite([ValidateRange(0, 10)][int]$seconds = 1,
    [string]$text = "",
    [string]$foregroundColor = "Black") {
    Write-Host "$text" -NoNewline -ForegroundColor $foregroundColor

    $basicCursorLeft = $text.Length * 2
    # Basic progress bar
    [Console]::CursorLeft = $basicCursorLeft
    [Console]::Write("[")
    [Console]::CursorLeft = $basicCursorLeft + $seconds + 1
    [Console]::Write("]")
    [Console]::CursorLeft = $basicCursorLeft + 1

    for ($seconds; $seconds -gt 0; $seconds--) {
        Write-Host "#" -NoNewline
        Start-Sleep -Milliseconds 1000
    }
}

try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Load-Config
    Check-File
    Load-ClashVersion
    Check-Update
    Out-Config
    Make-MainMenu
}
catch [System.Management.Automation.RuntimeException] {
    $errorInfo = "Error: " + $_.Exception.Message
    Write-Host ""
    Start-SleepAndWrite 5 $errorInfo Red
    Stop-Applications
    Disable-Proxy
    Out-Config
    exit 1
}
