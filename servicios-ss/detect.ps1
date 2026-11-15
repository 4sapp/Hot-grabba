<#
Read-only collection of possible Windows service/log integrity indicators.
Late process starts, short log history and absent Prefetch are leads, not proof.
No installs, service changes, registry writes, evidence deletion or log clearing.
Redirect output to a file under C:\ss-bypass-poc if persistence is wanted.
#>
[CmdletBinding()]
param([ValidateRange(1,1440)][int]$LateStartMinutes = 5)
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$names = @('DiagTrack','PcaSvc','DPS','SysMain','EventLog','WerSvc','EventSystem','Schedule')
function Show-Section([string]$Heading, [scriptblock]$Body) {
    Write-Output "`n=== $Heading ==="
    try { & $Body | Out-String -Width 180 | Write-Output }
    catch {
        if ($_.Exception.Message -like 'No events were found*') { Write-Output 'No matching events observed in the retained log.' }
        else { Write-Output ("UNAVAILABLE: " + $_.Exception.Message) }
    }
}
$boot = $null
try { $boot = (Get-CimInstance Win32_OperatingSystem -ErrorAction Stop).LastBootUpTime }
catch { Write-Output ("BOOT TIME UNAVAILABLE: " + $_.Exception.Message) }
Show-Section 'Context and exact checker' {
    Get-Date -Format o
    [pscustomobject]@{LastBootUpTime=$boot;UptimeHours=$(if ($boot) {[math]::Round(((Get-Date)-$boot).TotalHours,2)} else {$null});LateProcessThresholdMinutes=$LateStartMinutes} | Format-List
    Get-Service DiagTrack,PcaSvc,DPS,SysMain,EventLog,WerSvc,EventSystem,Schedule -ErrorAction SilentlyContinue | ft Name,Status,StartType -AutoSize
}
Show-Section 'Recent System service state transitions (7036; up to 60)' {
    Get-WinEvent -FilterHashtable @{LogName='System';Id=7036} -MaxEvents 60 -ErrorAction Stop |
        Select-Object TimeCreated,RecordId,Id,Message | Format-Table -Wrap -AutoSize
}
Show-Section 'Service process age relative to boot' {
    foreach ($name in $names) {
        try {
            $svc = Get-CimInstance Win32_Service -Filter "Name='$name'" -ErrorAction Stop
            if ($null -eq $svc) { throw "Service absent: $name" }
            $started = $null
            $note = 'No active service process; this may be normal for demand/trigger start.'
            $late = $null
            $delta = $null
            if ($svc.ProcessId -gt 0) {
                try {
                    $started = (Get-Process -Id $svc.ProcessId -ErrorAction Stop).StartTime
                    $note = 'Process lifetime is not service lifetime; a shared host can conceal a service restart.'
                    if ($boot -and $started) {
                        $delta = [math]::Round(($started - $boot).TotalMinutes,2)
                        $late = $delta -gt $LateStartMinutes
                    }
                } catch { $note = 'Process time unavailable (permissions, process exit, or race): ' + $_.Exception.Message }
            }
            [pscustomobject]@{Service=$name;State=$svc.State;StartMode=$svc.StartMode;ProcessId=$svc.ProcessId;ProcessStartTime=$started;MinutesAfterBoot=$delta;LateProcessIndicator=$late;Caveat=$note} | Format-List
        } catch { Write-Output ("UNAVAILABLE [$name]: " + $_.Exception.Message) }
    }
}
foreach ($log in @('System','Application')) {
    Show-Section "$log continuity and file size" {
        $meta = Get-WinEvent -ListLog $log -ErrorAction Stop
        $meta | Select-Object LogName,IsEnabled,RecordCount,LogMode,LogFilePath,FileSize,MaximumSizeInBytes | Format-List
        if ($meta.LogFilePath) {
            Get-Item -LiteralPath ([Environment]::ExpandEnvironmentVariables($meta.LogFilePath)) -ErrorAction Stop | Select-Object FullName,Length,CreationTime,LastWriteTime | Format-List
        }
        $first = Get-WinEvent -LogName $log -Oldest -MaxEvents 1 -ErrorAction Stop
        $last = Get-WinEvent -LogName $log -MaxEvents 1 -ErrorAction Stop
        [pscustomobject]@{Log=$log;EarliestTime=$first.TimeCreated;EarliestRecordId=$first.RecordId;LatestTime=$last.TimeCreated;LatestRecordId=$last.RecordId;EarliestMinutesAfterBoot=$(if ($boot -and $first.TimeCreated) {[math]::Round(($first.TimeCreated-$boot).TotalMinutes,2)} else {$null})} | Format-List
        'Short history can reflect retention rollover, new/provisioned logs, or clearing. Confirm with clearing records and a trusted baseline.'
    }
}
Show-Section 'System log configuration (wevtutil gl System)' {
    & wevtutil.exe gl System
    "wevtutil exit code: $LASTEXITCODE"
}
Show-Section 'System log-cleared records (provider Microsoft-Windows-Eventlog, ID 104)' {
    Get-WinEvent -FilterHashtable @{LogName='System';ProviderName='Microsoft-Windows-Eventlog';Id=104} -MaxEvents 20 -ErrorAction Stop |
        Select-Object TimeCreated,RecordId,Id,Message | Format-Table -Wrap -AutoSize
}
Show-Section 'Security audit-log-cleared records (ID 1102)' {
    Get-WinEvent -FilterHashtable @{LogName='Security';Id=1102} -MaxEvents 10 -ErrorAction Stop |
        Select-Object TimeCreated,RecordId,Id,Message | Format-Table -Wrap -AutoSize
    # 1102 relates to clearing Security; clearing Application does not imply 1102.
}
Show-Section 'Prefetch inventory and configuration' {
    $path = 'C:\Windows\Prefetch'
    $exists = Test-Path -LiteralPath $path -ErrorAction Stop
    if ($exists) {
        $files = @(Get-ChildItem -LiteralPath $path -Filter '*.pf' -File -ErrorAction Stop)
        [pscustomobject]@{DirectoryExists=$true;Count=$files.Count;OldestLastWriteTime=($files | Sort-Object LastWriteTime | Select-Object -First 1 -ExpandProperty LastWriteTime);NewestLastWriteTime=($files | Sort-Object LastWriteTime -Descending | Select-Object -First 1 -ExpandProperty LastWriteTime)} | Format-List
    } else { 'Prefetch directory absent; no assumption that files were deleted.' }
    $reg = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters'
    if (Test-Path -LiteralPath $reg -ErrorAction Stop) {
        Get-ItemProperty -LiteralPath $reg -ErrorAction Stop | Select-Object EnablePrefetcher,EnableSuperfetch | Format-List
    } else { 'PrefetchParameters registry key absent.' }
    'Empty/fresh Prefetch can reflect OS defaults (especially Server), provisioning, low execution activity, or cleanup. Missing configuration values do not establish effective policy.'
}
Show-Section 'PCA artifact metadata' {
    foreach ($p in @('C:\Windows\AppCompat\PCA\PcaAppLaunchDic.txt','C:\Windows\AppCompat\PCA\PcaGeneralDb0.txt')) {
        $exists = Test-Path -LiteralPath $p -ErrorAction Stop
        [pscustomobject]@{Path=$p;Exists=$exists;LastWriteTime=$(if ($exists) {(Get-Item -LiteralPath $p -ErrorAction Stop).LastWriteTime} else {$null})} | Format-List
    }
    'PCA artifact availability varies with Windows version/configuration; absence alone is not tampering evidence.'
}
foreach ($name in $names) {
    Show-Section "Trigger configuration: $name" {
        & sc.exe qtriggerinfo $name
        "sc.exe exit code: $LASTEXITCODE"
    }
}
Show-Section 'Registry service configuration (Start: 0 Boot; 1 System; 2 Auto; 3 Demand; 4 Disabled)' {
    foreach ($name in $names) {
        try {
            $v = Get-ItemProperty -LiteralPath "HKLM:\SYSTEM\CurrentControlSet\Services\$name" -ErrorAction Stop
            [pscustomobject]@{Service=$name;Start=$v.Start;DelayedAutoStart=$v.DelayedAutoStart;Type=$v.Type} | Format-Table -AutoSize
        } catch { Write-Output ("UNAVAILABLE [$name]: " + $_.Exception.Message) }
    }
    'Current Start values describe configuration now, not past state, effective defaults, or proof of integrity.'
}
Write-Output "`nRead-only collection complete. Correlate indicators; this script does not issue a cheating verdict."
