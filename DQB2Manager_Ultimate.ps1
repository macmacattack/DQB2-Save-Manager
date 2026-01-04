# v1.6.3 Release - UI Polish (Fixed Text Overlap)
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# --- 1. C# ACCELERATOR (High Performance Image Extraction) ---
$csharpSource = @"
using System;
using System.IO;

public class BitmapExtractor {
    public static bool Extract(string inputFile, string outputFile) {
        if (!File.Exists(inputFile)) return false;

        try {
            byte[] bytes = File.ReadAllBytes(inputFile);
            // DQB2 CMNDAT.BIN Offset Logic
            int startOffset = 269;
            int width = 320;
            int height = 180;
            int pixelSize = 3; // BGR24
            int imgSize = width * height * pixelSize;

            if (bytes.Length < startOffset + imgSize) return false;

            // Construct BMP Header (54 bytes)
            int fileSize = 54 + imgSize;
            byte[] header = new byte[54];
            header[0] = 0x42; // B
            header[1] = 0x4D; // M
            BitConverter.GetBytes(fileSize).CopyTo(header, 2);
            BitConverter.GetBytes(54).CopyTo(header, 10);
            BitConverter.GetBytes(40).CopyTo(header, 14);
            BitConverter.GetBytes(width).CopyTo(header, 18);
            BitConverter.GetBytes(-height).CopyTo(header, 22); // Negative for Top-Down
            BitConverter.GetBytes((short)1).CopyTo(header, 26);
            BitConverter.GetBytes((short)24).CopyTo(header, 28);

            using (FileStream fs = new FileStream(outputFile, FileMode.Create)) {
                fs.Write(header, 0, 54);
                fs.Write(bytes, startOffset, imgSize);
            }
            return true;
        } catch { return false; }
    }
}
"@
Add-Type -TypeDefinition $csharpSource -Language CSharp

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

# --- GUI SETUP ---
$form = New-Object System.Windows.Forms.Form
$form.Text = "DQB2 Save Manager v1.6.3"
$form.Size = New-Object System.Drawing.Size(870, 750)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedSingle"
$form.MaximizeBox = $false
$form.BackColor = "#F4F4F9"

$grpLive = New-Object System.Windows.Forms.GroupBox
$grpLive.Text = "Active Game Slots"
$grpLive.Location = New-Object System.Drawing.Point(15, 15)
$grpLive.Size = New-Object System.Drawing.Size(400, 600)
[void]$form.Controls.Add($grpLive)

$grpArc = New-Object System.Windows.Forms.GroupBox
$grpArc.Text = "Archive Library (Right-Click for Options)"
$grpArc.Location = New-Object System.Drawing.Point(430, 15)
$grpArc.Size = New-Object System.Drawing.Size(405, 600)
[void]$form.Controls.Add($grpArc)

$lstArchive = New-Object System.Windows.Forms.ListBox
$lstArchive.Location = New-Object System.Drawing.Point(15, 30)
$lstArchive.Size = New-Object System.Drawing.Size(375, 250)
[void]$grpArc.Controls.Add($lstArchive)

# --- CONTEXT MENU ---
$ctxMenu = New-Object System.Windows.Forms.ContextMenuStrip
$itemRename = $ctxMenu.Items.Add("Rename")
$itemRegen = $ctxMenu.Items.Add("Regenerate Image")
[void]$ctxMenu.Items.Add("-")
$itemDelete = $ctxMenu.Items.Add("Delete")
$lstArchive.ContextMenuStrip = $ctxMenu

$picPreview = New-Object System.Windows.Forms.PictureBox
$picPreview.Location = New-Object System.Drawing.Point(15, 290)
$picPreview.Size = New-Object System.Drawing.Size(375, 150)
$picPreview.BorderStyle = "FixedSingle"
$picPreview.SizeMode = "Zoom"
$picPreview.BackColor = "#000000"
[void]$grpArc.Controls.Add($picPreview)

# --- NEW ALBUM OPTIONS ---
$grpOptions = New-Object System.Windows.Forms.GroupBox
$grpOptions.Text = "Album Options (SCSHDAT.BIN)"
$grpOptions.Location = New-Object System.Drawing.Point(15, 450)
$grpOptions.Size = New-Object System.Drawing.Size(375, 90)
[void]$grpArc.Controls.Add($grpOptions)

# Backup Option (Left Column)
$chkBackupAlbum = New-Object System.Windows.Forms.CheckBox
$chkBackupAlbum.Text = "Include in Backup"
$chkBackupAlbum.Checked = $true
$chkBackupAlbum.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$chkBackupAlbum.Location = New-Object System.Drawing.Point(10, 25)
$chkBackupAlbum.Size = New-Object System.Drawing.Size(150, 20)
[void]$grpOptions.Controls.Add($chkBackupAlbum)

$lblBackupDesc = New-Object System.Windows.Forms.Label
$lblBackupDesc.Text = "Saves your photos with this backup."
$lblBackupDesc.ForeColor = "Gray"
$lblBackupDesc.Location = New-Object System.Drawing.Point(27, 45)
$lblBackupDesc.Size = New-Object System.Drawing.Size(155, 30) # Reduced width to prevent overlap
[void]$grpOptions.Controls.Add($lblBackupDesc)

# Restore Option (Right Column - Shifted Right)
$chkRestoreAlbum = New-Object System.Windows.Forms.CheckBox
$chkRestoreAlbum.Text = "Overwrite on Restore"
$chkRestoreAlbum.Checked = $true
$chkRestoreAlbum.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$chkRestoreAlbum.Location = New-Object System.Drawing.Point(190, 25) # Shifted to 190
$chkRestoreAlbum.Size = New-Object System.Drawing.Size(180, 20)
[void]$grpOptions.Controls.Add($chkRestoreAlbum)

$lblRestoreDesc = New-Object System.Windows.Forms.Label
$lblRestoreDesc.Text = "Warning: Replaces current album."
$lblRestoreDesc.ForeColor = "Red"
$lblRestoreDesc.Location = New-Object System.Drawing.Point(207, 45) # Shifted to 207 (aligned with checkbox)
$lblRestoreDesc.Size = New-Object System.Drawing.Size(160, 30)
[void]$grpOptions.Controls.Add($lblRestoreDesc)


# --- HELPER: GET CLEAN NAME ---
function Get-RealName($selection) {
    if (-not $selection) { return $null }
    return ($selection -split " \| ")[0]
}

# --- HELPER: CHECK IF GAME IS RUNNING ---
function Test-GameRunning {
    $proc = Get-Process "DQB2" -ErrorAction SilentlyContinue
    if ($proc) {
        [System.Windows.Forms.MessageBox]::Show("Please close Dragon Quest Builders 2 first!`n`nModifying saves while the game is running can corrupt data.", "Game is Running", "OK", "Error")
        return $true
    }
    return $false
}

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
            
            if (-not (Test-Path $tempImg)) {
                 [BitmapExtractor]::Extract("$fullPath\CMNDAT.BIN", $tempImg) | Out-Null
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
    $dirs = Get-ChildItem -Path $archivePath -Directory | Sort-Object LastWriteTime -Descending
    foreach ($d in $dirs) { 
        $display = "$($d.Name) | $($d.LastWriteTime.ToString('MMM dd, yyyy @ h:mm tt'))"
        [void]$lstArchive.Items.Add($display) 
    }
    $picPreview.Image = $null
}

function Backup-Process($slotName) {
    if (Test-GameRunning) { return }
    if (-not $slotName) { return }
    $name = [Microsoft.VisualBasic.Interaction]::InputBox("Name this save:", "Backup", "My Save")
    if (-not $name) { return }
    
    $form.Cursor = [System.Windows.Forms.Cursors]::WaitCursor

    $dest = Join-Path $archivePath $name
    if (Test-Path $dest) { 
        $form.Cursor = [System.Windows.Forms.Cursors]::Default
        $res = [System.Windows.Forms.MessageBox]::Show("Backup '$name' already exists.`nOverwrite it?", "Confirm Overwrite", "YesNo", "Warning")
        if ($res -eq "No") { return }
        $form.Cursor = [System.Windows.Forms.Cursors]::WaitCursor
        try { Remove-Item -Path $dest -Recurse -Force } catch { 
            $form.Cursor = [System.Windows.Forms.Cursors]::Default
            return 
        }
    }
    
    New-Item -ItemType Directory -Path $dest -Force | Out-Null
    $src = Join-Path $gameSavePath $slots[$slotName]
    
    # --- SPLIT LOGIC: BACKUP ---
    if ($chkBackupAlbum.Checked) {
        Copy-Item -Path "$src\*" -Destination $dest -Recurse
    } else {
        # Exclude SCSHDAT.BIN if unchecked
        Get-ChildItem -Path $src -Exclude "SCSHDAT.BIN" | Copy-Item -Destination $dest -Recurse
    }
    
    $archiveImg = Join-Path $dest "preview.bmp"
    [BitmapExtractor]::Extract("$dest\CMNDAT.BIN", $archiveImg) | Out-Null
    
    Refresh-UI
    $form.Cursor = [System.Windows.Forms.Cursors]::Default
}

function Restore-Process($targetSlot) {
    if (Test-GameRunning) { return }
    $rawSel = $lstArchive.SelectedItem
    $sel = Get-RealName $rawSel
    if (-not $sel) { return }
    
    # --- DYNAMIC WARNING MESSAGE ---
    $confirmMsg = "Restore '$sel' to $targetSlot?"
    
    if ($chkRestoreAlbum.Checked) {
        $confirmMsg += "`n`nWARNING: This will OVERWRITE your current Photo Album with the one from the backup."
        $confirmMsg += "`n(Uncheck 'Overwrite on Restore' to keep your current album)."
    } else {
        $confirmMsg += "`n`nNOTE: Your current Photo Album will be PRESERVED (Global Album Mode)."
    }

    if ([System.Windows.Forms.MessageBox]::Show($confirmMsg, "Confirm Restore", "YesNo", "Warning") -eq "Yes") {
        $form.Cursor = [System.Windows.Forms.Cursors]::WaitCursor

        $src = Join-Path $archivePath $sel
        $dest = Join-Path $gameSavePath $slots[$targetSlot]
        
        # --- SPLIT LOGIC: RESTORE ---
        if ($chkRestoreAlbum.Checked) {
             # OVERWRITE MODE: Nuclear Wipe (Standard)
             if (Test-Path $dest) { Remove-Item -Path $dest -Recurse -Force }
             New-Item -ItemType Directory -Path $dest -Force | Out-Null
             
             Get-ChildItem -Path $src -Exclude "preview.bmp" | Copy-Item -Destination $dest -Recurse
        } 
        else {
             # PRESERVE MODE: Delete everything EXCEPT SCSHDAT.BIN
             if (Test-Path $dest) {
                 Get-ChildItem -Path $dest | Where-Object { $_.Name -ne "SCSHDAT.BIN" } | Remove-Item -Recurse -Force
             }
             if (-not (Test-Path $dest)) { New-Item -ItemType Directory -Path $dest -Force | Out-Null }
             
             # Copy everything EXCEPT SCSHDAT.BIN (and preview.bmp)
             $excludes = @("preview.bmp", "SCSHDAT.BIN")
             Get-ChildItem -Path $src -Exclude $excludes | Copy-Item -Destination $dest -Recurse
        }
        
        $archivePreview = Join-Path $src "preview.bmp"
        $livePreview = Join-Path $tempPath "$targetSlot.bmp"
        if (Test-Path $archivePreview) { Copy-Item -Path $archivePreview -Destination $livePreview -Force }
        
        Refresh-UI
        $form.Cursor = [System.Windows.Forms.Cursors]::Default
        [System.Windows.Forms.MessageBox]::Show("Restored!")
    }
}

function Delete-Archive {
    $sel = Get-RealName $lstArchive.SelectedItem
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
    $sel = Get-RealName $lstArchive.SelectedItem
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
    $sel = Get-RealName $lstArchive.SelectedItem
    if (-not $sel) { return }
    
    $path = Join-Path $archivePath $sel
    $img = Join-Path $path "preview.bmp"
    
    $success = [BitmapExtractor]::Extract("$path\CMNDAT.BIN", $img)
    
    if ($success) {
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

# --- RESTORE BUTTONS ---
$btnR1 = New-Object System.Windows.Forms.Button; $btnR1.Text="Restore to Slot 1"; $btnR1.Location=New-Object System.Drawing.Point(15,560); $btnR1.Size=New-Object System.Drawing.Size(115,30); $btnR1.Add_Click({Restore-Process "Slot 1"}); [void]$grpArc.Controls.Add($btnR1)
$btnR2 = New-Object System.Windows.Forms.Button; $btnR2.Text="Restore to Slot 2"; $btnR2.Location=New-Object System.Drawing.Point(145,560); $btnR2.Size=New-Object System.Drawing.Size(115,30); $btnR2.Add_Click({Restore-Process "Slot 2"}); [void]$grpArc.Controls.Add($btnR2)
$btnR3 = New-Object System.Windows.Forms.Button; $btnR3.Text="Restore to Slot 3"; $btnR3.Location=New-Object System.Drawing.Point(275,560); $btnR3.Size=New-Object System.Drawing.Size(115,30); $btnR3.Add_Click({Restore-Process "Slot 3"}); [void]$grpArc.Controls.Add($btnR3)

# --- UTILITY BUTTONS ---
$btnDel = New-Object System.Windows.Forms.Button; $btnDel.Text="X"; $btnDel.ForeColor="Red"; $btnDel.Location=New-Object System.Drawing.Point(355,30); $btnDel.Size=New-Object System.Drawing.Size(35,25); $btnDel.Add_Click({Delete-Archive}); [void]$grpArc.Controls.Add($btnDel)

# --- OPEN FOLDER BUTTON ---
$btnOpenFolder = New-Object System.Windows.Forms.Button
$btnOpenFolder.Text = "Open Save Folder"
$btnOpenFolder.Location = New-Object System.Drawing.Point(558, 630)
$btnOpenFolder.Size = New-Object System.Drawing.Size(150, 30)
$btnOpenFolder.Add_Click({
    if (Test-Path $gameSavePath) { Invoke-Item $gameSavePath }
    else { [System.Windows.Forms.MessageBox]::Show("Game path not found.") }
})
[void]$form.Controls.Add($btnOpenFolder)

# --- LIST SELECTION CHANGE ---
$lstArchive.Add_SelectedIndexChanged({
    $sel = Get-RealName $lstArchive.SelectedItem
    if ($sel) {
        $img = Join-Path $archivePath "$sel\preview.bmp"
        if (Test-Path $img) { $picPreview.ImageLocation = $img } else { $picPreview.Image = $null }
    }
})

# Make right-click select the item first
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