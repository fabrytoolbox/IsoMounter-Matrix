# IsoMounter-Matrix.ps1 - v2.6
# Monta e smonta ISO con GUI Matrix, log e pulizia automatica

#Requires -Version 7.2

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ========================= AUTO-ELEVAZIONE ADMIN =========================
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    [System.Windows.Forms.MessageBox]::Show("Rilancio come Amministratore...", "Privilegi", "OK", "Information")
    $pwshPath = Join-Path $PSHOME "pwsh.exe"
    if (-not (Test-Path $pwshPath)) { $pwshPath = "pwsh.exe" }
    Start-Process $pwshPath -ArgumentList "-NoProfile -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$jsonFile   = Join-Path $scriptPath "mounted_isos.json"
$script:logFile = $null

# ========================= LOGGING =========================
function Start-Log {
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $script:logFile = Join-Path $scriptPath "isomounter_$timestamp.log"
    @(
        "============================================================",
        " ISO MOUNTER - LOG",
        "============================================================",
        "Data inizio: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')",
        "============================================================",
        ""
    ) | Set-Content -Path $script:logFile -Encoding UTF8
}

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    if (-not $script:logFile) { return }
    $line = "[$(Get-Date -Format 'HH:mm:ss')] [$Level] $Message"
    Add-Content -Path $script:logFile -Value $line -Encoding UTF8
}

Start-Log

# ========================= GESTIONE DATI =========================
function Get-MountedIsos {
    if (Test-Path $jsonFile) {
        try {
            $content = Get-Content $jsonFile -Raw
            if ([string]::IsNullOrWhiteSpace($content)) { return @() }
            $data = $content | ConvertFrom-Json
            return ,@($data)
        } catch { return @() }
    }
    return @()
}

function Save-MountedIsos ($data) {
    try { 
        $json = if ($null -ne $data -and $data.Count -gt 0) { $data | ConvertTo-Json -Depth 4 } else { "[]" }
        Set-Content $jsonFile $json -Force 
    } catch { 
        Write-Log "Errore salvataggio JSON: $($_.Exception.Message)" "ERROR"
    }
}

# ========================= LOGICA REFRESH =========================
function Refresh-List {
    $listBox.Items.Clear()
    $isos = Get-MountedIsos
    $validIsos = @()
    
    foreach ($iso in $isos) { 
        if ($null -ne $iso.DisplayString) {
            # Verifica se l'ISO è ancora montato
            $isMounted = $false
            try {
                $disk = Get-DiskImage -ImagePath $iso.ImagePath -ErrorAction SilentlyContinue
                if ($disk -and $disk.Attached) { $isMounted = $true }
            } catch { }
            
            if ($isMounted) {
                [void]$listBox.Items.Add($iso.DisplayString)
                $validIsos += $iso
            } else {
                Write-Log "ISO non più montato (rimosso dal JSON): $($iso.ImagePath)" "WARN"
            }
        }
    }
    
    # Aggiorna il JSON se ci sono state rimozioni
    if ($validIsos.Count -ne $isos.Count) {
        Save-MountedIsos $validIsos
    }
    
    $hasItems = $listBox.Items.Count -gt 0
    $dismountBtn.Enabled = $hasItems
    $dismountAllBtn.Enabled = $hasItems
}

# ========================= AZIONI =========================
function Mount-ISO ($path) {
    if (-not (Test-Path $path)) { 
        [Windows.Forms.MessageBox]::Show("File non trovato: $path", "Errore", "OK", "Error")
        return 
    }
    try {
        $disk = Mount-DiskImage -ImagePath $path -PassThru -ErrorAction Stop
        $letter = (Get-Volume -DiskImage $disk -ErrorAction SilentlyContinue).DriveLetter
        $display = Split-Path $path -Leaf
        if ($letter) { $display += " [$letter`:]" }
        
        $list = Get-MountedIsos | Where-Object { $null -ne $_ -and $_.ImagePath -ne $path }
        $list += [pscustomobject]@{ ImagePath = $path; DriveLetter = $letter; DisplayString = $display }
        Save-MountedIsos $list
        Refresh-List
        Write-Log "ISO montato: $path (Lettera: $letter)" "OK"
    } catch { 
        Write-Log "Errore montaggio: $($_.Exception.Message)" "ERROR"
        [Windows.Forms.MessageBox]::Show("Errore caricamento ISO: $($_.Exception.Message)", "Errore", "OK", "Error") 
    }
}

function Dismount-ISO ($entry) {
    if ($null -eq $entry) { return }
    try {
        if ($entry.ImagePath) {
            Dismount-DiskImage -ImagePath $entry.ImagePath -ErrorAction Stop | Out-Null
            Write-Log "ISO smontato: $($entry.ImagePath)" "OK"
        }
        $list = Get-MountedIsos | Where-Object { $null -ne $_ -and $_.ImagePath -ne $entry.ImagePath }
        Save-MountedIsos $list
        Refresh-List
    } catch { 
        Write-Log "Errore smontaggio: $($_.Exception.Message)" "ERROR"
        [Windows.Forms.MessageBox]::Show("Errore smontaggio: $($_.Exception.Message)", "Errore", "OK", "Error")
    }
}

# ========================= GUI =========================
$form = New-Object Windows.Forms.Form
$form.Text = "ISO MOUNTER - MATRIX CORE"; $form.Size = '520,550'; $form.BackColor = "Black"; $form.FormBorderStyle = "FixedSingle"; $form.StartPosition = "CenterScreen"

$lblTitle = New-Object Windows.Forms.Label
$lblTitle.Text = "VIRTUAL DISK INTERFACE"; $lblTitle.ForeColor = "Lime"; $lblTitle.Font = 'Consolas, 14, style=Bold'; $lblTitle.Location = '20,15'; $lblTitle.Size = '470,30'; $lblTitle.TextAlign = "MiddleCenter"; $form.Controls.Add($lblTitle)

$textBox = New-Object Windows.Forms.TextBox
$textBox.Location = '20,60'; $textBox.Size = '350,25'; $textBox.BackColor = "Black"; $textBox.ForeColor = "Lime"; $textBox.ReadOnly = $true; $form.Controls.Add($textBox)

$browseBtn = New-Object Windows.Forms.Button
$browseBtn.Text = "BROWSE"; $browseBtn.Location = '380,58'; $browseBtn.Size = '110,28'; $browseBtn.FlatStyle = "Flat"; $browseBtn.ForeColor = "Lime"; $browseBtn.FlatAppearance.BorderColor = "Lime"; $form.Controls.Add($browseBtn)

$mountBtn = New-Object Windows.Forms.Button
$mountBtn.Text = "MOUNT ISO"; $mountBtn.Location = '20,100'; $mountBtn.Size = '470,45'; $mountBtn.BackColor = "Lime"; $mountBtn.ForeColor = "Black"; $mountBtn.Font = 'Consolas, 11, style=Bold'; $mountBtn.FlatStyle = "Flat"; $mountBtn.Enabled = $false; $form.Controls.Add($mountBtn)

$listBox = New-Object Windows.Forms.ListBox
$listBox.Location = '20,170'; $listBox.Size = '470,180'; $listBox.BackColor = "Black"; $listBox.ForeColor = "Lime"; $listBox.BorderStyle = "FixedSingle"; $listBox.Font = 'Consolas, 10'; $form.Controls.Add($listBox)

$dismountBtn = New-Object Windows.Forms.Button
$dismountBtn.Text = "DISMOUNT SELECTED"; $dismountBtn.Location = '20,370'; $dismountBtn.Size = '230,45'; $dismountBtn.FlatStyle = "Flat"; $dismountBtn.ForeColor = "Lime"; $dismountBtn.FlatAppearance.BorderColor = "Lime"; $dismountBtn.Enabled = $false; $form.Controls.Add($dismountBtn)

$dismountAllBtn = New-Object Windows.Forms.Button
$dismountAllBtn.Text = "DISMOUNT ALL"; $dismountAllBtn.Location = '260,370'; $dismountAllBtn.Size = '230,45'; $dismountAllBtn.FlatStyle = "Flat"; $dismountAllBtn.ForeColor = "Lime"; $dismountAllBtn.FlatAppearance.BorderColor = "Lime"; $dismountAllBtn.Enabled = $false; $form.Controls.Add($dismountAllBtn)

$exitBtn = New-Object Windows.Forms.Button
$exitBtn.Text = "TERMINATE SESSION"; $exitBtn.Location = '20,440'; $exitBtn.Size = '470,40'; $exitBtn.FlatStyle = "Flat"; $exitBtn.ForeColor = "DarkGray"; $exitBtn.FlatAppearance.BorderColor = "DimGray"; $exitBtn.Add_Click({ $form.Close() }); $form.Controls.Add($exitBtn)

# ========================= EVENTI =========================
$browseBtn.Add_Click({
    $dlg = New-Object Windows.Forms.OpenFileDialog
    $dlg.Filter = "ISO Files (*.iso)|*.iso"
    if ($dlg.ShowDialog() -eq "OK") { $textBox.Text = $dlg.FileName; $mountBtn.Enabled = $true }
})

$mountBtn.Add_Click({ Mount-ISO $textBox.Text })

$dismountBtn.Add_Click({
    $idx = $listBox.SelectedIndex
    if ($idx -ge 0) {
        $currentIsos = Get-MountedIsos
        if ($idx -lt $currentIsos.Count) {
            Dismount-ISO $currentIsos[$idx]
        }
    }
})

$dismountAllBtn.Add_Click({ 
    $isos = Get-MountedIsos
    foreach ($iso in $isos) { Dismount-ISO $iso }
})

$form.AllowDrop = $true
$form.Add_DragEnter({ $_.Effect = "Copy" })
$form.Add_DragDrop({
    $files = $_.Data.GetData([Windows.Forms.DataFormats]::FileDrop)
    if ($files[0].ToLower().EndsWith(".iso")) { $textBox.Text = $files[0]; $mountBtn.Enabled = $true }
})

$form.Add_Shown({ Refresh-List })
[void]$form.ShowDialog()
