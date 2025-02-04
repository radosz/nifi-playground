@echo off
setlocal enabledelayedexpansion

REM -------------------------------------------------
REM Load environment variables from .env
REM -------------------------------------------------
for /f "tokens=1,2 delims==" %%i in (.env) do (
    set %%i=%%j
)

REM -------------------------------------------------
REM Cleanup any previously generated files
REM -------------------------------------------------
if exist keystore.p12 del keystore.p12
if exist truststore.p12 del truststore.p12
if exist public.pem del public.pem
if exist private.pem del private.pem
if exist %HOSTNAME%.pem del %HOSTNAME%.pem
if exist %HOSTNAME%-key.pem del %HOSTNAME%-key.pem

REM -------------------------------------------------
REM Step 1: Generate certificate using mkcert directly for %HOSTNAME%
REM -------------------------------------------------
echo Generating certificate for %HOSTNAME% with mkcert...
mkcert %HOSTNAME%

REM -------------------------------------------------
REM Step 2: Create PEM files directly from PKCS12
REM -------------------------------------------------
echo Creating PKCS12 keystore first...
openssl pkcs12 -export ^
  -in %HOSTNAME%.pem ^
  -inkey %HOSTNAME%-key.pem ^
  -name nifi ^
  -out keystore.p12 ^
  -passout pass:%KEYSTORE_PASSWORD%

echo Extracting public certificate from PKCS12...
openssl pkcs12 -in keystore.p12 -passin pass:%KEYSTORE_PASSWORD% -nokeys -out public.pem

echo Extracting private key from PKCS12...
openssl pkcs12 -in keystore.p12 -passin pass:%KEYSTORE_PASSWORD% -nocerts -nodes -out private.pem

REM Cleanup temporary files
del %HOSTNAME%.pem
del %HOSTNAME%-key.pem

REM -------------------------------------------------
REM Step 3: Create a Truststore using mkcert's CA certificate
REM -------------------------------------------------
echo Retrieving mkcert CA root directory...
for /f "usebackq delims=" %%i in (`mkcert -CAROOT`) do set CAROOT=%%i

echo Creating truststore (truststore.p12) using mkcert's root CA...
keytool -importcert -trustcacerts ^
  -alias mkcertCA ^
  -file "%CAROOT%\rootCA.pem" ^
  -keystore truststore.p12 ^
  -storetype PKCS12 ^
  -storepass %TRUSTSTORE_PASSWORD% ^
  -noprompt

REM -------------------------------------------------
REM Step 4: Copy CA root certificate for potential future use
REM -------------------------------------------------
echo Copying mkcert root CA certificate...
copy "%CAROOT%\rootCA.pem" rootCA.pem

REM -------------------------------------------------
REM Display summary and verification information
REM -------------------------------------------------
echo.
echo All files generated successfully!
echo.
echo Generated files:
echo   1. Certificate files:
echo      - public.pem (Public Certificate)
echo      - private.pem (Private Key)
echo      - rootCA.pem (Root CA Certificate)
echo.
echo   2. Keystore/Truststore:
echo      - keystore.p12 (Password: %KEYSTORE_PASSWORD%)
echo      - truststore.p12 (Password: %TRUSTSTORE_PASSWORD%)
echo.
echo These files will be mounted to:
echo   - /opt/nifi/nifi-current/conf/keystore.p12
echo   - /opt/nifi/nifi-current/conf/truststore.p12
echo.
echo The PEM files are extracted from PKCS12 and should be directly usable in browsers.
echo.

endlocal
