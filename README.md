# WingetScripts

## WingetAppInstall.ps1

A PowerShell script for managing Winget package installations and updates.  
This script automates the process of installing missing applications and updating existing ones from a `winget.json` configuration file.

### 📌 Features
- Installs applications listed in `winget.json` if they are not already installed.
- Updates applications that have newer versions available.
- Logs all operations to `WingetAppInstall.log`.
- Provides a **single summary at the end** listing all installed or updated applications.

### 📝 Requirements
- **Windows 10 / Windows 11**
- **PowerShell 5.1 or later**
- **Administrator privileges** (Run PowerShell as Admin)
- **Microsoft.Winget.Client module** must be installed

### 📂 Usage
1. Ensure `winget.json` contains the list of applications to install and is in the same folder as the script.
2. Open PowerShell as Administrator.
3. Run the script:
   ```powershell
   .\WingetAppInstall.ps1
   ```
4. View installation logs in `WingetAppInstall.log`.

### 🖊️ Changes Made
This script is **based on an original script by Richard Hicks**, with the following modifications:
- **Logging added** – All actions are logged in `WingetAppInstall.log`.
- **Final log summary added** – Instead of showing installation details for each app, a single log summary appears at the end.
- **No duplicate console logs** – Keeps PowerShell output clean.

---

## UpdateWingetPackages.ps1

This script is **unaltered** and remains as originally written by **Richard Hicks**.

### 📌 Features
- Checks for Winget package updates.
- Allows users to select updates via a graphical interface using `Out-ConsoleGridView`.
- Supports parallel updates for improved performance.
- Logs update results, including error handling for failed updates.
- Uses an exclusion list (`WingetUpdateExclude.txt`) to prevent certain apps from being updated.

### 📝 Requirements
- **PowerShell 7.3 or later**
- **PowerShell Module:** `Microsoft.Winget.Client`
- **PowerShell Module:** `Microsoft.PowerShell.ConsoleGuiTools`

---

## 🔗 Credits
- **Original Scripts:** Richard Hicks ([richardhicks.com](https://richardhicks.com/))  
- **WingetAppInstall.ps1 Modified by:** [Kjetil Furås](https://github.com/kfuras)  
- **UpdateWingetPackages.ps1:** Unmodified from the original author
