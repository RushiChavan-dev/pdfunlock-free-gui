# PDF Unlock GUI

Small Windows tool for creating unlocked PDF copies without converting pages to images. It uses `qpdf` through the included `pdfunlock.bat` file.

## What You Need

- Windows
- PowerShell, included with Windows
- `qpdf` installed and available in `PATH`

To install `qpdf` with Windows Package Manager:

```bat
winget install -e --id QPDF.QPDF
```

## Files

- `pdfunlock-gui.bat` - double-click this to open the GUI.
- `pdfunlock-gui.ps1` - the PowerShell GUI script.
- `pdfunlock.bat` - command-line unlock script used by the GUI.

## How To Use

1. Double-click `pdfunlock-gui.bat`.
2. Click `Select PDFs`.
3. Select one or more PDF files.
4. Leave the password option as `No password`, unless the PDF requires one.
5. Click `Unlock`.

Unlocked copies are saved in the same folder as the selected PDF files.

Example:

```text
contract.pdf
contract-unlock.pdf
```

If a file named `contract-unlock.pdf` already exists, the GUI creates the next available name, such as `contract-unlock-2.pdf`.

## Password-Protected PDFs

If a PDF requires a password:

1. Choose `user` or `owner` from the dropdown.
2. Enter the password.
3. Click `Unlock`.

Use `user` for a view/open password. Use `owner` for an edit/permissions password.

## Command-Line Use

You can also run the batch file directly:

```bat
pdfunlock.bat "locked.pdf" "locked-unlock.pdf"
```

With a password:

```bat
pdfunlock.bat "locked.pdf" "locked-unlock.pdf" user "password"
pdfunlock.bat "locked.pdf" "locked-unlock.pdf" owner "password"
```
