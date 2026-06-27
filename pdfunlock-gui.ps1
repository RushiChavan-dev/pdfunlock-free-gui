Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$unlockBat = Join-Path $scriptDir "pdfunlock.bat"

function New-UnlockPath {
    param([string]$Path)

    $directory = Split-Path -Parent $Path
    $name = [System.IO.Path]::GetFileNameWithoutExtension($Path)
    $extension = [System.IO.Path]::GetExtension($Path)
    $candidate = Join-Path $directory "$name-unlock$extension"

    $index = 2
    while (Test-Path -LiteralPath $candidate) {
        $candidate = Join-Path $directory "$name-unlock-$index$extension"
        $index++
    }

    return $candidate
}

function Add-LogLine {
    param([string]$Text)

    $logBox.AppendText("$Text`r`n")
    $logBox.SelectionStart = $logBox.TextLength
    $logBox.ScrollToCaret()
    [System.Windows.Forms.Application]::DoEvents()
}

if (-not (Test-Path -LiteralPath $unlockBat)) {
    [System.Windows.Forms.MessageBox]::Show(
        "Cannot find pdfunlock.bat in $scriptDir",
        "PDF Unlock GUI",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Error
    ) | Out-Null
    exit 1
}

$form = New-Object System.Windows.Forms.Form
$form.Text = "PDF Unlock"
$form.Size = New-Object System.Drawing.Size(620, 430)
$form.StartPosition = "CenterScreen"
$form.MinimumSize = New-Object System.Drawing.Size(560, 360)

$selectButton = New-Object System.Windows.Forms.Button
$selectButton.Text = "Select PDFs"
$selectButton.Location = New-Object System.Drawing.Point(12, 12)
$selectButton.Size = New-Object System.Drawing.Size(120, 34)

$unlockButton = New-Object System.Windows.Forms.Button
$unlockButton.Text = "Unlock"
$unlockButton.Location = New-Object System.Drawing.Point(142, 12)
$unlockButton.Size = New-Object System.Drawing.Size(100, 34)
$unlockButton.Enabled = $false

$clearButton = New-Object System.Windows.Forms.Button
$clearButton.Text = "Clear"
$clearButton.Location = New-Object System.Drawing.Point(252, 12)
$clearButton.Size = New-Object System.Drawing.Size(90, 34)

$passwordType = New-Object System.Windows.Forms.ComboBox
$passwordType.DropDownStyle = "DropDownList"
$passwordType.Location = New-Object System.Drawing.Point(352, 17)
$passwordType.Size = New-Object System.Drawing.Size(110, 24)
[void]$passwordType.Items.Add("No password")
[void]$passwordType.Items.Add("user")
[void]$passwordType.Items.Add("owner")
$passwordType.SelectedIndex = 0

$passwordBox = New-Object System.Windows.Forms.TextBox
$passwordBox.Location = New-Object System.Drawing.Point(472, 17)
$passwordBox.Size = New-Object System.Drawing.Size(120, 24)
$passwordBox.UseSystemPasswordChar = $true
$passwordBox.Enabled = $false

$fileList = New-Object System.Windows.Forms.ListBox
$fileList.Location = New-Object System.Drawing.Point(12, 58)
$fileList.Size = New-Object System.Drawing.Size(580, 180)
$fileList.Anchor = "Top,Left,Right"
$fileList.HorizontalScrollbar = $true

$logBox = New-Object System.Windows.Forms.TextBox
$logBox.Location = New-Object System.Drawing.Point(12, 250)
$logBox.Size = New-Object System.Drawing.Size(580, 130)
$logBox.Anchor = "Top,Bottom,Left,Right"
$logBox.Multiline = $true
$logBox.ReadOnly = $true
$logBox.ScrollBars = "Vertical"

$dialog = New-Object System.Windows.Forms.OpenFileDialog
$dialog.Title = "Select PDF files to unlock"
$dialog.Filter = "PDF files (*.pdf)|*.pdf|All files (*.*)|*.*"
$dialog.Multiselect = $true
$dialog.InitialDirectory = $scriptDir

$passwordType.Add_SelectedIndexChanged({
    $passwordBox.Enabled = ($passwordType.SelectedItem -ne "No password")
    if (-not $passwordBox.Enabled) {
        $passwordBox.Clear()
    }
})

$selectButton.Add_Click({
    if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        foreach ($file in $dialog.FileNames) {
            if (-not $fileList.Items.Contains($file)) {
                [void]$fileList.Items.Add($file)
            }
        }
        $unlockButton.Enabled = ($fileList.Items.Count -gt 0)
        Add-LogLine "Selected $($fileList.Items.Count) file(s)."
    }
})

$clearButton.Add_Click({
    $fileList.Items.Clear()
    $logBox.Clear()
    $unlockButton.Enabled = $false
})

$unlockButton.Add_Click({
    $selectButton.Enabled = $false
    $unlockButton.Enabled = $false
    $clearButton.Enabled = $false

    try {
        $successCount = 0
        $failCount = 0

        foreach ($item in @($fileList.Items)) {
            $inputPath = [string]$item
            $outputPath = New-UnlockPath -Path $inputPath

            Add-LogLine ""
            Add-LogLine "Unlocking: $inputPath"
            Add-LogLine "Saving as: $outputPath"

            $process = New-Object System.Diagnostics.Process
            $process.StartInfo.FileName = $unlockBat
            if ($passwordType.SelectedItem -eq "No password") {
                $process.StartInfo.Arguments = "`"$inputPath`" `"$outputPath`""
            } else {
                $process.StartInfo.Arguments = "`"$inputPath`" `"$outputPath`" $($passwordType.SelectedItem) `"$($passwordBox.Text)`""
            }
            $process.StartInfo.WorkingDirectory = $scriptDir
            $process.StartInfo.UseShellExecute = $false
            $process.StartInfo.RedirectStandardOutput = $true
            $process.StartInfo.RedirectStandardError = $true
            $process.StartInfo.CreateNoWindow = $true

            [void]$process.Start()
            $stdout = $process.StandardOutput.ReadToEnd()
            $stderr = $process.StandardError.ReadToEnd()
            $process.WaitForExit()

            if ($stdout.Trim()) {
                Add-LogLine $stdout.TrimEnd()
            }
            if ($stderr.Trim()) {
                Add-LogLine $stderr.TrimEnd()
            }

            if ($process.ExitCode -eq 0) {
                $successCount++
                Add-LogLine "Success."
            } else {
                $failCount++
                Add-LogLine "Failed with exit code $($process.ExitCode)."
            }
        }

        Add-LogLine ""
        Add-LogLine "Finished. $successCount succeeded, $failCount failed."
    } catch {
        Add-LogLine ""
        Add-LogLine "Error: $($_.Exception.Message)"
    } finally {
        $selectButton.Enabled = $true
        $clearButton.Enabled = $true
        $unlockButton.Enabled = ($fileList.Items.Count -gt 0)
    }
})

$form.Controls.AddRange(@($selectButton, $unlockButton, $clearButton, $passwordType, $passwordBox, $fileList, $logBox))
[void]$form.ShowDialog()
