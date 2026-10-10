# autocad-watchdog.ps1 - GTG COMPUTER
# Cek berkala (scheduled task, jalan sebagai user biasa, tanpa admin):
#  [1] bunuh otomatis koneksi internet milik proses Autodesk
#  [2] pastikan rule firewall kunci masih ada
#  [3] pastikan hosts masih diblokir + service tetap disabled (lapor saja)
# Notifikasi Windows toast HANYA muncul saat ada masalah BARU (anti-spam).
param([switch]$Test)

$GTG = Join-Path $env:LOCALAPPDATA 'GTG'
if (-not (Test-Path $GTG)) { New-Item -ItemType Directory -Path $GTG -Force | Out-Null }
$log = Join-Path $GTG 'watchdog.log'
$stateFile = Join-Path $GTG 'watchdog.state'

function WLog($m) {
  Add-Content -Path $log -Value ("[{0:yyyy-MM-dd HH:mm:ss}] {1}" -f (Get-Date), $m) -ErrorAction SilentlyContinue
}

function Show-Toast($title, $msg) {
  try {
    [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
    $tpl = [Windows.UI.Notifications.ToastNotificationManager]::GetTemplateContent([Windows.UI.Notifications.ToastTemplateType]::ToastText02)
    $xml = [xml]$tpl.GetXml()
    $xml.toast.visual.binding.text[0].AppendChild($xml.CreateTextNode($title)) | Out-Null
    $xml.toast.visual.binding.text[1].AppendChild($xml.CreateTextNode($msg)) | Out-Null
    $t = [Windows.UI.Notifications.ToastNotification]::new($xml)
    [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier('GTG.AutoCADWatchdog').Show($t)
  } catch { WLog "toast gagal: $_" }
}

if ($Test) { Show-Toast 'GTG Watchdog' 'Tes notifikasi OK - watchdog aktif.'; exit 0 }

$problems = @()

# [1] koneksi aktif -> kill otomatis
try {
  $conns = @(Get-NetTCPConnection -State Established -ErrorAction Stop | Where-Object {
    try { (Get-Process -Id $_.OwningProcess -ErrorAction Stop).Path -like '*Autodesk*' } catch { $false }
  })
} catch { $conns = @() }
$killed = @()
foreach ($c in $conns) {
  try {
    $p = Get-Process -Id $c.OwningProcess -ErrorAction Stop
    Stop-Process -Id $p.Id -Force -ErrorAction Stop
    $killed += "$($p.ProcessName) -> $($c.RemoteAddress)"
    WLog "KILL: $($p.ProcessName) -> $($c.RemoteAddress):$($c.RemotePort)"
  } catch { $problems += "Koneksi Autodesk tak bisa dimatikan: $($c.RemoteAddress):$($c.RemotePort)" }
}
if ($killed.Count -gt 0) { $problems += "Koneksi Autodesk dimatikan otomatis: $($killed -join ', ')" }

# [2] rule firewall kunci (wildcard, tahan beda varian nama)
$rules = @(Get-NetFirewallRule -DisplayName 'Blokir AutoCAD*' -ErrorAction SilentlyContinue | Select-Object -ExpandProperty DisplayName)
$need = @('acad.exe', 'AcWebBrowser', 'GenuineService', 'AdSync', 'AdAppMgrSvc')
$missing = @($need | Where-Object { $n = $_; -not ($rules | Where-Object { $_ -like "*$n*" }) })
if ($missing.Count -gt 0) { $problems += "Rule firewall hilang: $($missing -join ', ') - jalankan toolkit [1]" }

# [3] hosts (canary: 3 domain kunci)
$h = Get-Content "$env:SystemRoot\System32\drivers\etc\hosts" -ErrorAction SilentlyContinue
$hmissing = @(@('genuine-software.autodesk.com','accounts.autodesk.com','cur.autodesk.com') | Where-Object { -not ($h -match [regex]::Escape($_)) })
if ($hmissing.Count -gt 0) { $problems += "Hosts belum blokir: $($hmissing -join ', ') - jalankan toolkit [1]" }

# [4] service (lapor saja - butuh admin untuk disable)
$bad = @()
foreach ($s in @('AdskGenuineService','AdskLicensingService','Autodesk Desktop App Service','FlexNet Licensing Service')) {
  $svc = Get-Service -Name $s -ErrorAction SilentlyContinue
  if ($svc -and $svc.StartType -ne 'Disabled') { $bad += $s }
}
if ($bad.Count -gt 0) { $problems += "Service aktif lagi: $($bad -join ', ') - jalankan toolkit [1] (admin)" }

# anti-spam: toast hanya jika masalah berubah
$sig = ($problems -join "`n")
$old = ''
if (Test-Path $stateFile) { $old = [string](Get-Content $stateFile -Raw -ErrorAction SilentlyContinue) }
if ($problems.Count -gt 0 -and $sig -ne $old.Trim()) {
  $msg = (($problems | Select-Object -First 3) -join "`n")
  if ($problems.Count -gt 3) { $msg += "`n(+$($problems.Count - 3) lainnya - cek log)" }
  Show-Toast 'GTG AutoCAD Watchdog' $msg
  WLog ("PROBLEM: " + ($problems -join ' | '))
}
$sig | Set-Content $stateFile -NoNewline -ErrorAction SilentlyContinue
