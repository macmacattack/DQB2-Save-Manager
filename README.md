# DQB2 Save Manager

A lightweight, high-performance application to manage, backup, restore, and organize *Dragon Quest Builders 2* save games on PC (Steam). It features instant C# based image extraction to view save file thumbnails directly within the app.

## 🌟 Features
- **Visual Interface:** Automatically detects active save slots (Slot 1, 2, 3).
- **Instant Previews:** Decodes the `CMNDAT.BIN` header to display the actual screenshot of your save file.
- **Archive Library:** Create unlimited named backups with automatic timestamps.
- **Safety First:** Detects if the game is running to prevent data corruption and prompts before overwriting.

## 📂 Folder Structure
When you run the application, it automatically creates two folders in the same directory:

* `DQB2_Archives` - **Your Backups Live Here.** Each subfolder represents a saved backup.
* `DQB2_Temp` - Used for temporary image processing (safe to ignore or delete).

## 🚀 Getting Started & Importing Saves
If you already have backup folders stored elsewhere, you can easily import them:

1.  Open the `DQB2_Archives` folder.
2.  Create a new folder for your save (e.g., `My Imported Save`).
3.  Paste your save files (must include `CMNDAT.BIN`) into that new folder.
4.  Launch **DQB2 Save Manager**.
5.  **Pro Tip:** If the preview image is missing or black, **Right-Click** the save in the list and select **Regenerate Image**.

## 📖 User Guide

### Backing Up a Save
1.  Look at the **"Active Game Slots"** panel on the left.
2.  Click the **Backup** button next to your desired slot.
3.  Enter a name (e.g., "Before Chapter 3 Boss") and press Enter.
4.  The save is now safe in your library.

### Restoring a Save
1.  Select a backup from the list on the right.
2.  Check the large preview image to confirm it is the correct file.
3.  Click **Restore to Slot X** at the bottom.
4.  Confirm the warning message.

### Managing Archives
**Right-click** any item in the Archive list to access:
* **Rename:** Change the name of your backup.
* **Regenerate Image:** Re-scans the save data to fix broken or missing thumbnails.
* **Delete:** Permanently remove the backup.

## 🛠️ How to Run
You can download the standalone `.exe` from the **Releases** tab, or run the raw script:

1.  Download `DQB2Manager_Ultimate.ps1`.
2.  Right-click the file and select **Run with PowerShell**.
    * *Note: If the window closes immediately, right-click > Properties > Check "Unblock".*

## 💻 Build Instructions (Advanced)
If you want to compile the script into an `.exe` yourself:

1.  **Install the compiler:**
    ```powershell
    Install-Module -Name ps2exe -Scope CurrentUser
    ```
2.  **Compile:**
    ```powershell
    Invoke-PS2EXE -InputFile ".\DQB2Manager_Ultimate.ps1" -OutputFile ".\DQB2SaveManager.exe" -NoConsole -title "DQB2 Save Manager v1.3"
    ```

## 🤝 Credits
* **Code & Development:** Developed with assistance from **Google Gemini**, serving as a pair programmer for PowerShell logic and WinForms GUI construction.
* **Image Decoding Logic:** Critical reference data for `CMNDAT.BIN` bitmap headers provided by [turtle-insect/DQB2](https://github.com/turtle-insect/DQB2).