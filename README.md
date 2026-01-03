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
