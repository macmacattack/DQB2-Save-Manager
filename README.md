# DQB2 Save Manager

A lightweight PowerShell application to manage, backup, restore, and organize *Dragon Quest Builders 2* save games on PC (Steam). It includes a raw image extractor to view save file thumbnails directly in the app.

## Features
- **Visual Interface:** Automatically detects active save slots (Slot 1, 2, 3).
- **Instant Previews:** Decodes the `CMNDAT.BIN` header to display the actual screenshot of your save file.
- **Archive Library:** Create unlimited named backups.
- **Safety First:** Prompts for confirmation before overwriting any active save slot.

## User Guide

### 1. Backing Up a Save
* Look at the **"Active Game Slots"** panel on the left.
* If a slot is populated, you will see its preview image.
* Click the **Backup** button next to the slot.
* Enter a name for your backup (e.g., "Before Chapter 3 Boss") and press Enter.
* The save is now safe in your **Archive Library**.

### 2. Restoring a Save
* Select a backup from the **Archive Library** list on the right.
* Check the preview image below the list to confirm it's the right one.
* Click one of the **Restore to Slot X** buttons at the bottom.
* Confirm the warning message to overwrite the current save data.

### 3. Managing Archives
* **Right-click** any item in the Archive list to bring up a menu:
    * **Rename:** Change the name of your backup.
    * **Regenerate Image:** Re-scans the save data to fix broken thumbnails.
    * **Delete:** Permanently remove the backup.

## How to Run
1.  Download `DQB2Manager_Ultimate.ps1`.
2.  Right-click the file and select **Run with PowerShell**.
    * *Note: If the window closes immediately, you may need to right-click > Properties > "Unblock", or run PowerShell as Administrator.*

## Development & Credits

* **Code & Development:** This tool was developed with significant assistance from **Google Gemini**, acting as a pair programmer to generate the PowerShell logic and WinForms GUI structure.
* **Save Data Image Logic:** Critical reference data for decoding the `CMNDAT.BIN` bitmap headers was provided by [turtle-insect/DQB2](https://github.com/turtle-insect/DQB2).

## Build Instructions (Converting to EXE)

If you prefer a standalone executable (`.exe`) instead of running the script directly, you can compile it using the **PS2EXE** module.

1.  **Install the compiler:**
    Open PowerShell as Administrator and run:
    ```powershell
    Install-Module -Name ps2exe -Scope CurrentUser
    ```

2.  **Compile the script:**
    Navigate to the project folder and run:
    ```powershell
    Invoke-PS2EXE -InputFile ".\DQB2Manager_Ultimate.ps1" -OutputFile ".\DQB2SaveManager.exe" -NoConsole -title "DQB2 Save Manager"
    ```
    * *Note: The `-NoConsole` switch is critical to prevent a black terminal window from appearing behind the GUI.*
=======
# DQB2 Save Manager

A lightweight PowerShell application to backup, restore, and organize *Dragon Quest Builders 2* save games on PC (Steam). It includes a raw image extractor to view save file thumbnails directly in the app.

## Features
- **Visual Interface:** Automatically detects active save slots.
- **Save Preview:** Decodes `CMNDAT.BIN` to display the actual screenshot of the save file.
- **Archive System:** Create named backups and restore them to any slot.
- **Safety:** Prevents overwriting valid saves without confirmation.

## How to Use
1. Download the script.
2. Right-click `DQB2Manager_Ultimate.ps1` and select **Run with PowerShell**.
   * *Note: You may need to unblock the file in properties or run `Set-ExecutionPolicy RemoteSigned` if strictly configured.*

## Credits & References
* **Save Data Image Logic:** Huge thanks to [turtle-insect/DQB2](https://github.com/turtle-insect/DQB2). Their analysis of the `CMNDAT.BIN` header structure and bitmap offsets was essential for the image extraction logic used in this tool.

