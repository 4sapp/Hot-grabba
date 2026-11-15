<#
Inventario defensivo de procesos y modulos del laboratorio.
Solo lectura: no configura proxy, no inyecta DLL, no cambia servicios.
El PID y los nombres de imagen son indicios; ni ruta ni firma bastan por si solos.
#>
[CmdletBinding()]
param([int[]]$ProcessIds = @())
$ErrorActionPreference = 'Stop'
$names = @('ModuleHost.exe','IdentitySample.exe','RuntimeBroker.exe')
$moduleNames = @('CheatPayload.dll','payload.dll')
Write-Output ('Captura UTC: ' + (Get-Date).ToUniversalTime().ToString('o'))
$targets = @(Get-CimInstance Win32_Process -ErrorAction Stop |
    Where-Object { $_.Name -in $names -and ($ProcessIds.Count -eq 0 -or $_.ProcessId -in $ProcessIds) } |
    Sort-Object Name,ProcessId)
if ($targets.Count -eq 0) { Write-Output 'Sin procesos objetivo disponibles para inspeccion.' }
foreach ($item in $targets) {
    Write-Output "`n=== Identidad: $($item.Name), PID $($item.ProcessId) ==="
    try {
        $path = $item.ExecutablePath
        if (-not $path) { throw 'No se obtuvo ruta ejecutable mediante Win32_Process.' }
        $file = Get-Item -LiteralPath $path -ErrorAction Stop
        $signature = Get-AuthenticodeSignature -LiteralPath $path -ErrorAction Stop
        $sigName = if ($signature.SignerCertificate) { $signature.SignerCertificate.Subject } else { '(sin certificado)' }
        $originalName = $file.VersionInfo.OriginalFilename
        $expected = @((Join-Path $env:windir 'System32\RuntimeBroker.exe'),(Join-Path $env:windir 'SysWOW64\RuntimeBroker.exe'))
        [pscustomobject]@{
            Name=$item.Name
            ProcessId=$item.ProcessId
            ParentProcessId=$item.ParentProcessId
            ExecutablePath=$path
            OriginalFilename=$originalName
            NameDiffersFromOriginal=([IO.Path]::GetFileName($path) -ine $originalName)
            RuntimeBrokerExpectedOSPath=$(if ($item.Name -eq 'RuntimeBroker.exe') { $path -in $expected } else { $null })
            SignatureStatus=$signature.Status
            SignerSubject=$sigName
            SHA256=(Get-FileHash -LiteralPath $path -Algorithm SHA256 -ErrorAction Stop).Hash
        } | Format-List | Out-String -Width 160 | Write-Output
    } catch { Write-Output ('Identidad no disponible: ' + $_.Exception.Message) }
    Write-Output "=== Modulos del PID $($item.ProcessId) ==="
    try {
        $process = Get-Process -Id $item.ProcessId -ErrorAction Stop
        $modules = @($process.Modules | Where-Object { $_.ModuleName -in $moduleNames })
        if ($modules.Count -gt 0) {
            $modules | Select-Object ModuleName,FileName,@{n='SignatureStatus';e={(Get-AuthenticodeSignature -LiteralPath $_.FileName).Status}} |
                Format-Table -AutoSize | Out-String -Width 160 | Write-Output
        } else { Write-Output 'Los modulos buscados no aparecen en la enumeracion nativa del proceso.' }
    } catch { Write-Output ('Enumeracion de modulos no disponible: ' + $_.Exception.Message) }
}
Write-Output "`n=== tasklist /m CheatPayload.dll: enumeracion nativa ==="
& tasklist.exe /m CheatPayload.dll
Write-Output ('tasklist exit code: ' + $LASTEXITCODE)
Write-Output "`n=== tasklist /m payload.dll: prueba de visibilidad de ensamblado .NET ==="
& tasklist.exe /m payload.dll
Write-Output ('tasklist exit code: ' + $LASTEXITCODE)
Write-Output "`n=== Configuracion e inventario Prefetch (no se infiere inyeccion) ==="
try {
    $reg = Get-ItemProperty -LiteralPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters' -ErrorAction Stop
    [pscustomobject]@{EnablePrefetcher=$reg.EnablePrefetcher;EnableSuperfetch=$reg.EnableSuperfetch} | Format-List | Out-String | Write-Output
    $pf = @(Get-ChildItem -LiteralPath 'C:\Windows\Prefetch' -Filter '*.pf' -File -ErrorAction Stop |
        Where-Object { $_.Name -match '^(ModuleHost|IdentitySample)-' })
    if ($pf.Count) { $pf | Select-Object Name,LastWriteTime,Length | Format-Table -AutoSize | Out-String | Write-Output }
    else { Write-Output 'Sin .pf coincidentes: ausencia no demuestra limpieza ni falta de ejecucion.' }
} catch { Write-Output ('Prefetch no disponible: ' + $_.Exception.Message) }
Write-Output "`n=== Archivos recientes del laboratorio (no busqueda global) ==="
Get-ChildItem -LiteralPath 'C:\antifake-poc' -File -ErrorAction Stop |
    Select-Object Name,LastWriteTime,Length | Sort-Object LastWriteTime -Descending |
    Format-Table -AutoSize | Out-String -Width 160 | Write-Output
Write-Output "`n=== Eventos 7036/7040: sin cambios de servicios en este experimento ==="
try {
    Get-WinEvent -FilterHashtable @{LogName='System';Id=7036,7040} -MaxEvents 8 -ErrorAction Stop |
        Select-Object TimeCreated,RecordId,Id,Message | Format-Table -Wrap -AutoSize | Out-String -Width 160 | Write-Output
} catch { Write-Output ('Consulta de eventos no disponible: ' + $_.Exception.Message) }
Write-Output 'Fin de deteccion de solo lectura. Contextualizar con baselines confiables.'
