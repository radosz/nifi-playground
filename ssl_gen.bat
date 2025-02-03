@echo off
setlocal enabledelayedexpansion

:: Load environment variables from .env file
for /f "tokens=1,2 delims==" %%i in (.env) do (
    set %%i=%%j
)

:: Delete existing files if they exist
if exist keystore.jks del keystore.jks
if exist truststore.jks del truststore.jks
if exist ca-cert.cer del ca-cert.cer
if exist ca-key del ca-key
if exist cert-file del cert-file
if exist cert-signed del cert-signed
if exist ca-cert.srl del ca-cert.srl
if exist san.ext del san.ext

:: Create SAN extension file with all required extensions
echo authorityKeyIdentifier=keyid,issuer > san.ext
echo basicConstraints=CA:FALSE >> san.ext
echo keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment >> san.ext
echo. >> san.ext
echo [alt_names] >> san.ext
echo DNS.1 = localhost >> san.ext
echo IP.1 = 127.0.0.1 >> san.ext

:: Step 1: Generate a keystore and keypair with localhost configuration
echo Generating keystore and keypair...
keytool -genkeypair -alias bmc -keyalg RSA -keystore keystore.jks -keysize 2048 -storepass %KEYSTORE_PASSWORD% -keypass %KEYSTORE_PASSWORD% -dname "CN=localhost, OU=NIFI, O=Apache, L=Unknown, ST=Unknown, C=US" -ext SAN=%SAN%

:: Step 2: Generate a CA certificate and key
echo Generating CA certificate and key...
openssl req -new -x509 -keyout ca-key -out ca-cert -days 365 -nodes -subj "/CN=localhost/OU=NIFI/O=Apache/L=Unknown/ST=Unknown/C=US"

:: Step 3: Generate a certificate signing request (CSR)
echo Generating certificate signing request...
keytool -certreq -alias bmc -keystore keystore.jks -file cert-file -storepass %KEYSTORE_PASSWORD% -ext SAN=%SAN%

:: Step 4: Sign the CSR with the CA certificate
echo Signing CSR with CA certificate...

openssl x509 -req -CA ca-cert -CAkey ca-key -in cert-file -out cert-signed -days 365 -CAcreateserial -extfile san.ext

:: Step 5: Import the CA certificate into the keystore
echo Importing CA certificate into keystore...
keytool -importcert -alias CARoot -keystore keystore.jks -file ca-cert -storepass %KEYSTORE_PASSWORD% -noprompt

:: Step 6: Import the signed certificate into the keystore
echo Importing signed certificate into keystore...
keytool -importcert -alias bmc -keystore keystore.jks -file cert-signed -storepass %KEYSTORE_PASSWORD% -noprompt

:: Step 7: Create and import the CA certificate into the truststore
echo Creating truststore and importing CA certificate...
keytool -importcert -alias CARoot -file ca-cert -keystore truststore.jks -storepass %TRUSTSTORE_PASSWORD% -noprompt

:: Steps 8, 9 still doesn't works
rem :: Step 8: Convert CA certificate to DER format for Windows
rem echo Converting CA certificate to DER format...
rem openssl x509 -in ca-cert -out ca-cert.cer -outform DER

rem :: Step 9: Add certificate to Windows Trust Store
rem echo Adding certificate to Windows Trust Store...
rem certutil -addstore -f "ROOT" ca-cert.cer

:: Delete non docker files
if exist ca-cert del ca-cert
if exist ca-key del ca-key
if exist cert-file del cert-file
if exist cert-signed del cert-signed
if exist ca-cert.srl del ca-cert.srl
if exist san.ext del san.ext

echo "All commands executed successfully!"
echo "Keystore Password: %KEYSTORE_PASSWORD%"
echo "Truststore Password: %TRUSTSTORE_PASSWORD%"
:: echo "Certificate has been added to Windows Trust Store"
endlocal
