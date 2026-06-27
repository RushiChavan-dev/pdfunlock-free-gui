@echo off
setlocal enabledelayedexpansion

REM PDFUnlock - Windows non-raster version
REM Uses qpdf only. Does not convert pages to images.
REM
REM Usage:
REM   pdfunlock-nonraster.bat "locked.pdf" "unlocked.pdf"
REM   pdfunlock-nonraster.bat "locked.pdf" "unlocked.pdf" user "viewPassword"
REM   pdfunlock-nonraster.bat "locked.pdf" "unlocked.pdf" owner "editPassword"

if "%~2"=="" goto usage

set "LOCKED_PDF=%~1"
set "UNLOCKED_PDF=%~2"
set "PASSWORD_TYPE=%~3"
set "PASSWORD=%~4"

where qpdf >nul 2>&1
if errorlevel 1 (
    echo qpdf not found.
    echo Install it using:
    echo winget install -e --id QPDF.QPDF
    exit /b 1
)

if not exist "%LOCKED_PDF%" (
    echo Cannot read locked PDF:
    echo "%LOCKED_PDF%"
    exit /b 3
)

if /I "%LOCKED_PDF%"=="%UNLOCKED_PDF%" (
    echo Input and output files must be different.
    exit /b 4
)

if "%PASSWORD_TYPE%"=="" (
    echo Checking PDF security...
    qpdf --show-encryption "%LOCKED_PDF%"

    echo.
    echo Creating non-raster copy...
    qpdf --decrypt "%LOCKED_PDF%" "%UNLOCKED_PDF%"
    goto done
)

if "%PASSWORD%"=="" (
    echo Password type was provided but password is missing.
    exit /b 3
)

if /I not "%PASSWORD_TYPE%"=="user" if /I not "%PASSWORD_TYPE%"=="owner" (
    echo Invalid password type: %PASSWORD_TYPE%
    echo Use: user or owner
    exit /b 3
)

echo Checking PDF security...
qpdf --password="%PASSWORD%" --show-encryption "%LOCKED_PDF%"

echo.
echo Creating non-raster copy...
qpdf --password="%PASSWORD%" --decrypt "%LOCKED_PDF%" "%UNLOCKED_PDF%"

goto done

:usage
echo PDFUnlock non-raster Windows version
echo.
echo Usage:
echo   %~nx0 "locked.pdf" "unlocked.pdf"
echo   %~nx0 "locked.pdf" "unlocked.pdf" user "viewPassword"
echo   %~nx0 "locked.pdf" "unlocked.pdf" owner "editPassword"
exit /b 2

:done
if errorlevel 1 (
    echo.
    echo Failed.
    echo If the PDF requires a password, provide the correct password.
    exit /b 5
)

echo.
echo Done.
echo Saved:
echo "%UNLOCKED_PDF%"
exit /b 0