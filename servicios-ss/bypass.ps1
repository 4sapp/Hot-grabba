<#
NON-DESTRUCTIVE CONTROL ONLY: this file does not implement a bypass.
It does not stop/start/reconfigure services, delete evidence, or clear logs.
Its output is a second observation, never proof that a bypass succeeded.
#>
[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
Write-Output 'CONTROL ONLY: no service changes, forensic deletion, or log clearing performed.'
Get-Date -Format o
Get-Service DiagTrack,PcaSvc,DPS,SysMain,EventLog,WerSvc,EventSystem,Schedule -ErrorAction SilentlyContinue | ft Name,Status,StartType -AutoSize
