@echo off
setlocal enabledelayedexpansion

echo Generating SSL certificates...

:: Check if OpenSSL exists
where openssl >nul 2>&1
if %errorlevel% neq 0 (
    echo OpenSSL is not installed.
    set "INSTALL_OPENSSL=1"
) else (
    echo OpenSSL is already installed.
)

:: Check if mkcert exists
where mkcert >nul 2>&1
if %errorlevel% neq 0 (
    echo mkcert is not installed.
    set "INSTALL_MKCERT=1"
) else (
    echo mkcert is already installed.
)

:: Check if keytool exists and JAVA_HOME is set
where keytool >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo WARNING: keytool is not found in PATH.
    echo This typically means that either:
    echo  1. Java JDK is not installed, or
    echo  2. JAVA_HOME environment variable is not properly set
    echo.
    echo Please follow these steps:
    echo  1. Download and install JDK from: https://adoptium.net/ or https://www.oracle.com/java/technologies/downloads/
    echo  2. Set JAVA_HOME environment variable to point to your JDK installation directory
    echo     Example: set JAVA_HOME=C:\Program Files\Java\jdk-17
    echo  3. Add %%JAVA_HOME%%\bin to your PATH environment variable
    echo.
    echo After installing JDK and setting JAVA_HOME, please run this script again.
    echo.
    set "KEYTOOL_MISSING=1"
) else (
    echo keytool is available.
)

:: If either program needs to be installed, check for Chocolatey
if defined INSTALL_OPENSSL set "NEED_CHOCO=1"
if defined INSTALL_MKCERT set "NEED_CHOCO=1"

if defined NEED_CHOCO (
    :: Check if Chocolatey is installed
    set "CHOCO_CHECK=choco --version"
    for /F "tokens=*" %%i in ('%CHOCO_CHECK% 2^>^&1') do set "CHOCO_OUTPUT=%%i"
    echo %CHOCO_OUTPUT% | find /I "not recognized" >nul
    if %errorlevel% equ 0 (
        echo Chocolatey is not installed. Installing Chocolatey...
        
        :: Install Chocolatey
        powershell.exe -NoProfile -InputFormat None -ExecutionPolicy Bypass -Command "[System.Net.ServicePointManager]::SecurityProtocol = 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))" && SET "PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin"
        
        if %errorlevel% neq 0 (
            echo Failed to install Chocolatey
            exit /b 1
        )
        
        :: Reset the PATH to include Chocolatey
        set "PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin"
        
        :: Verify Chocolatey installation
        where choco >nul 2>&1
        if %errorlevel% neq 0 (
            echo Chocolatey installation failed verification
            exit /b 1
        )
    ) else (
        echo Chocolatey is already installed.
    )

    :: Install OpenSSL if needed
    if defined INSTALL_OPENSSL (
        echo Installing OpenSSL...
        choco install openssl --version=3.4.0 -y
        if !errorlevel! neq 0 (
            echo Failed to install OpenSSL
            exit /b 1
        )
    )
    
    :: Install mkcert if needed
    if defined INSTALL_MKCERT (
        echo Installing mkcert...
        choco install mkcert --version=1.4.4 -y
        if !errorlevel! neq 0 (
            echo Failed to install mkcert
            exit /b 1
        )
    )
)

:: Final status check
echo.
echo Installation Status:
if not defined INSTALL_OPENSSL (
    echo - OpenSSL: Already installed
) else (
    echo - OpenSSL: Newly installed
)

if not defined INSTALL_MKCERT (
    echo - mkcert: Already installed
) else (
    echo - mkcert: Newly installed
)

if defined KEYTOOL_MISSING (
    echo - keytool: NOT AVAILABLE - Please install JDK and set JAVA_HOME
    echo.
    exit /b 1
) else (
    echo - keytool: Available
)

echo.
if defined KEYTOOL_MISSING (
    echo Some required tools are missing. Please address the issues above.
) else (
    echo All required programs are installed and available.
    call ssl_gen.bat
    IF !ERRORLEVEL! NEQ 0 (
        echo SSL certificate generation failed!
        exit /b !ERRORLEVEL!
    ) ELSE (
        echo SSL certificates generated successfully.
        echo Building and starting NiFi container...
        docker-compose up -d --build
        IF !ERRORLEVEL! NEQ 0 (
            echo Docker build/start failed!
            exit /b !ERRORLEVEL!
        ) ELSE (
            echo NiFi should be available shortly at https://nifi:8443/nifi
        )
    )
)

endlocal
