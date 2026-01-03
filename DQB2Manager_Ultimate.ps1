Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# --- NUCLEAR PATH DETECTION ---
try {
    if ($PSScriptRoot) {
        $rootPath = $PSScriptRoot
    } else {
        $process = [System.Diagnostics.Process]::GetCurrentProcess()
        $fullPath = $process.MainModule.FileName
        $rootPath = [System.IO.Path]::GetDirectoryName($fullPath)
    }
} catch {
    $rootPath = [System.AppDomain]::CurrentDomain.BaseDirectory
}

# --- DIRECTORIES ---
$archivePath = Join-Path $rootPath "DQB2_Archives"
$tempPath = Join-Path $rootPath "DQB2_Temp"

try {
    if (-not (Test-Path $archivePath)) { New-Item -ItemType Directory -Path $archivePath -Force | Out-Null }
    if (-not (Test-Path $tempPath)) { New-Item -ItemType Directory -Path $tempPath -Force | Out-Null }
} catch {}

# --- DETECT GAME SAVE FOLDER ---
$userProfile = $env:USERPROFILE
$steamBasePath = Join-Path $userProfile "Documents\My Games\DRAGON QUEST BUILDERS II\Steam"
$gameSavePath = $null

if (Test-Path $steamBasePath) {
    $subfolders = Get-ChildItem -Path $steamBasePath -Directory
    foreach ($folder in $subfolders) {
        if (Test-Path "$($folder.FullName)\SD") {
            $gameSavePath = "$($folder.FullName)\SD"
            break
        }
    }
}
if (-not $gameSavePath) { $gameSavePath = "C:\" }

$slots = @{ "Slot 1" = "B00"; "Slot 2" = "B01"; "Slot 3" = "B02" }

# --- EXTRACTION ENGINE (RAW BITMAP) ---
function Extract-RawImage($folderPath, $destPath) {
    $filePath = Join-Path $folderPath "CMNDAT.BIN"
    if (-not (Test-Path $filePath)) { return $false }

    try {
        $bytes = [System.IO.File]::ReadAllBytes($filePath)
        
        # Source Code Offset: 0x10D = 269
        $startOffset = 269
        $width = 320
        $height = 180
        $pixelSize = 3 # BGR24
        $imgSize = $width * $height * $pixelSize # 172,800 bytes
        
        if ($bytes.Length -lt ($startOffset + $imgSize)) { return $false }

        # 1. Extract Raw Pixels
        $rawPixels = New-Object byte[] $imgSize
        [Array]::Copy($bytes, $startOffset, $rawPixels, 0, $imgSize)
        
        # 2. Construct BMP Header (54 bytes)
        $fileSize = 54 + $imgSize
        $header = New-Object byte[] 54
        
        $header[0] = 0x42 # B
        $header[1] = 0x4D # M
        [BitConverter]::GetBytes([int]$fileSize).CopyTo($header, 2)
        [BitConverter]::GetBytes([int]54).CopyTo($header, 10) # Data Offset
        [BitConverter]::GetBytes([int]40).CopyTo($header, 14) # Header Size
        [BitConverter]::GetBytes([int]$width).CopyTo($header, 18)
        [BitConverter]::GetBytes([int]($height * -1)).CopyTo($header, 22) # Negative Height (Top-Down)
        [BitConverter]::GetBytes([int16]1).CopyTo($header, 26)  # Planes
        [BitConverter]::GetBytes([int16]24).CopyTo($header, 28) # Bit Count
        
        # 3. Combine & Save
        $finalBmp = $header + $rawPixels
        [System.IO.File]::WriteAllBytes($destPath, $finalBmp)
        
        return $true
    } catch { return $false }
}

# --- GUI ---
$form = New-Object System.Windows.Forms.Form
$form.Text = "DQB2 Save Manager"
$form.Size = New-Object System.Drawing.Size(850, 600)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedSingle"
$form.MaximizeBox = $false
$form.BackColor = "#F4F4F9"

$grpLive = New-Object System.Windows.Forms.GroupBox
$grpLive.Text = "Active Game Slots"
$grpLive.Location = New-Object System.Drawing.Point(15, 15)
$grpLive.Size = New-Object System.Drawing.Size(400, 530)
[void]$form.Controls.Add($grpLive)

$grpArc = New-Object System.Windows.Forms.GroupBox
$grpArc.Text = "Archive Library (Right-Click for Options)"
$grpArc.Location = New-Object System.Drawing.Point(430, 15)
$grpArc.Size = New-Object System.Drawing.Size(390, 530)
[void]$form.Controls.Add($grpArc)

$lstArchive = New-Object System.Windows.Forms.ListBox
$lstArchive.Location = New-Object System.Drawing.Point(15, 30)
$lstArchive.Size = New-Object System.Drawing.Size(360, 250)
[void]$grpArc.Controls.Add($lstArchive)

# --- CONTEXT MENU (RIGHT CLICK) ---
$ctxMenu = New-Object System.Windows.Forms.ContextMenuStrip
$itemRename = $ctxMenu.Items.Add("Rename")
$itemRegen = $ctxMenu.Items.Add("Regenerate Image")
[void]$ctxMenu.Items.Add("-")
$itemDelete = $ctxMenu.Items.Add("Delete")
$lstArchive.ContextMenuStrip = $ctxMenu

$picPreview = New-Object System.Windows.Forms.PictureBox
$picPreview.Location = New-Object System.Drawing.Point(15, 290)
$picPreview.Size = New-Object System.Drawing.Size(360, 200)
$picPreview.BorderStyle = "FixedSingle"
$picPreview.SizeMode = "Zoom"
$picPreview.BackColor = "#000000"
[void]$grpArc.Controls.Add($picPreview)

# --- LOGIC ---
function Refresh-UI {
    $grpLive.Controls.Clear()
    
    $keysArray = $slots.Keys | Sort-Object
    for ([int]$i = 0; $i -lt $keysArray.Count; $i++) {
        $key = $keysArray[$i]
        $folder = $slots[$key]
        $fullPath = Join-Path $gameSavePath $folder
        
        [int]$offset = $i * 150
        [int]$baseY = 30 + $offset
        
        $pnl = New-Object System.Windows.Forms.Panel
        $pnl.Location = New-Object System.Drawing.Point(10, $baseY)
        $pnl.Size = New-Object System.Drawing.Size(380, 140)
        $pnl.BorderStyle = "FixedSingle"
        [void]$grpLive.Controls.Add($pnl)

        $lbl = New-Object System.Windows.Forms.Label
        $lbl.Text = "$key"
        $lbl.Location = New-Object System.Drawing.Point(10, 10)
        $lbl.AutoSize = $true
        $lbl.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
        [void]$pnl.Controls.Add($lbl)

        if ((Test-Path $fullPath) -and (Get-ChildItem $fullPath)) {
            $status = New-Object System.Windows.Forms.Label
            $status.Text = "ACTIVE"
            $status.ForeColor = "DarkGreen"
            $status.Location = New-Object System.Drawing.Point(70, 12)
            [void]$pnl.Controls.Add($status)
            
            $livePic = New-Object System.Windows.Forms.PictureBox
            $livePic.Location = New-Object System.Drawing.Point(10, 40)
            $livePic.Size = New-Object System.Drawing.Size(160, 90)
            $livePic.SizeMode = "Zoom"
            $livePic.BorderStyle = "FixedSingle"
            [void]$pnl.Controls.Add($livePic)

            $tempImg = Join-Path $tempPath "$key.bmp"
            
            # Auto-Extract if missing
            if (-not (Test-Path $tempImg)) {
                 Extract-RawImage $fullPath $tempImg | Out-Null
            }
            if (Test-Path $tempImg) { $livePic.ImageLocation = $tempImg }

            $btn = New-Object System.Windows.Forms.Button
            $btn.Text = "Backup"
            $btn.Location = New-Object System.Drawing.Point(190, 40)
            $btn.Size = New-Object System.Drawing.Size(120, 40)
            $btn.Tag = $key 
            $btn.Add_Click({ 
                $slotName = $this.Tag
                Backup-Process $slotName 
            })
            [void]$pnl.Controls.Add($btn)

        } else {
            $status = New-Object System.Windows.Forms.Label
            $status.Text = "EMPTY"
            $status.ForeColor = "Gray"
            $status.Location = New-Object System.Drawing.Point(70, 12)
            [void]$pnl.Controls.Add($status)
        }
    }

    $lstArchive.Items.Clear()
    $dirs = Get-ChildItem -Path $archivePath -Directory
    foreach ($d in $dirs) { 
        [void]$lstArchive.Items.Add($d.Name) 
    }
    $picPreview.Image = $null
}

function Backup-Process($slotName) {
    if (-not $slotName) { return }
    $name = [Microsoft.VisualBasic.Interaction]::InputBox("Name this save:", "Backup", "My Save")
    if (-not $name) { return }
    
    $dest = Join-Path $archivePath $name
    if (Test-Path $dest) { 
        $res = [System.Windows.Forms.MessageBox]::Show("Backup '$name' already exists.`nOverwrite it?", "Confirm Overwrite", "YesNo", "Warning")
        if ($res -eq "No") { return }
        try { Remove-Item -Path $dest -Recurse -Force } catch { return }
    }
    
    New-Item -ItemType Directory -Path $dest -Force | Out-Null
    $src = Join-Path $gameSavePath $slots[$slotName]
    Copy-Item -Path "$src\*" -Destination $dest -Recurse
    
    # Extract Preview
    $archiveImg = Join-Path $dest "preview.bmp"
    Extract-RawImage $dest $archiveImg | Out-Null
    Refresh-UI
}

function Restore-Process($targetSlot) {
    $sel = $lstArchive.SelectedItem
    if (-not $sel) { return }
    
    if ([System.Windows.Forms.MessageBox]::Show("Overwrite $targetSlot with '$sel'?", "Confirm", "YesNo", "Warning") -eq "Yes") {
        $src = Join-Path $archivePath $sel
        $dest = Join-Path $gameSavePath $slots[$targetSlot]
        
        if (Test-Path $dest) { Remove-Item -Path $dest -Recurse -Force }
        New-Item -ItemType Directory -Path $dest -Force | Out-Null
        
        Get-ChildItem -Path $src -Exclude "preview.bmp" | Copy-Item -Destination $dest -Recurse
        
        $archivePreview = Join-Path $src "preview.bmp"
        $livePreview = Join-Path $tempPath "$targetSlot.bmp"
        if (Test-Path $archivePreview) { Copy-Item -Path $archivePreview -Destination $livePreview -Force }
        
        [System.Windows.Forms.MessageBox]::Show("Restored!")
        Refresh-UI
    }
}

function Delete-Archive {
    $sel = $lstArchive.SelectedItem
    if ($sel) {
        if ([System.Windows.Forms.MessageBox]::Show("Delete '$sel'?", "Confirm", "YesNo") -eq "Yes") {
            try {
                Remove-Item -Path (Join-Path $archivePath $sel) -Recurse -Force
                Refresh-UI
            } catch {}
        }
    }
}

function Rename-Archive {
    $sel = $lstArchive.SelectedItem
    if (-not $sel) { return }
    
    $newName = [Microsoft.VisualBasic.Interaction]::InputBox("Enter new name:", "Rename Backup", $sel)
    if (-not $newName -or $newName -eq $sel) { return }
    
    $oldPath = Join-Path $archivePath $sel
    $newPath = Join-Path $archivePath $newName
    
    if (Test-Path $newPath) {
        [System.Windows.Forms.MessageBox]::Show("A backup with that name already exists!", "Error")
        return
    }
    
    try {
        Rename-Item -Path $oldPath -NewName $newName
        Refresh-UI
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Could not rename. Folder might be open.", "Error")
    }
}

function Regenerate-Image {
    $sel = $lstArchive.SelectedItem
    if (-not $sel) { return }
    
    $path = Join-Path $archivePath $sel
    $img = Join-Path $path "preview.bmp"
    
    $success = Extract-RawImage $path $img
    
    if ($success) {
        # Force refresh the picture box
        $picPreview.ImageLocation = $img
        [System.Windows.Forms.MessageBox]::Show("Image regenerated successfully!", "Success")
    } else {
        [System.Windows.Forms.MessageBox]::Show("Failed to regenerate image.`nCMNDAT.BIN might be missing or corrupt.", "Error")
    }
}

# --- MENU EVENTS ---
$itemRename.Add_Click({ Rename-Archive })
$itemDelete.Add_Click({ Delete-Archive })
$itemRegen.Add_Click({ Regenerate-Image })

# --- BUTTONS ---
$btnR1 = New-Object System.Windows.Forms.Button; $btnR1.Text="Restore to Slot 1"; $btnR1.Location=New-Object System.Drawing.Point(15,500); $btnR1.Size=New-Object System.Drawing.Size(110,30); $btnR1.Add_Click({Restore-Process "Slot 1"}); [void]$grpArc.Controls.Add($btnR1)
$btnR2 = New-Object System.Windows.Forms.Button; $btnR2.Text="Restore to Slot 2"; $btnR2.Location=New-Object System.Drawing.Point(135,500); $btnR2.Size=New-Object System.Drawing.Size(110,30); $btnR2.Add_Click({Restore-Process "Slot 2"}); [void]$grpArc.Controls.Add($btnR2)
$btnR3 = New-Object System.Windows.Forms.Button; $btnR3.Text="Restore to Slot 3"; $btnR3.Location=New-Object System.Drawing.Point(255,500); $btnR3.Size=New-Object System.Drawing.Size(110,30); $btnR3.Add_Click({Restore-Process "Slot 3"}); [void]$grpArc.Controls.Add($btnR3)

$btnDel = New-Object System.Windows.Forms.Button; $btnDel.Text="X"; $btnDel.ForeColor="Red"; $btnDel.Location=New-Object System.Drawing.Point(340,30); $btnDel.Size=New-Object System.Drawing.Size(35,25); $btnDel.Add_Click({Delete-Archive}); [void]$grpArc.Controls.Add($btnDel)

# --- LIST SELECTION CHANGE ---
$lstArchive.Add_SelectedIndexChanged({
    if ($lstArchive.SelectedItem) {
        $img = Join-Path $archivePath "$($lstArchive.SelectedItem)\preview.bmp"
        if (Test-Path $img) { $picPreview.ImageLocation = $img } else { $picPreview.Image = $null }
    }
})

# Make right-click select the item first (UX improvement)
$lstArchive.Add_MouseDown({
    param($sender, $e)
    if ($e.Button -eq 'Right') {
        $idx = $lstArchive.IndexFromPoint($e.Location)
        if ($idx -ne -1) { $lstArchive.SelectedIndex = $idx }
    }
})

[void][System.Reflection.Assembly]::Load("Microsoft.VisualBasic, Version=10.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a")

Refresh-UI
[void]$form.ShowDialog()