@echo off
echo Generating SSL certificates...
call ssl_gen.bat

IF %ERRORLEVEL% NEQ 0 (
    echo SSL certificate generation failed!
    exit /b %ERRORLEVEL%
) ELSE (
    echo SSL certificates generated successfully.
    echo Building and starting NiFi container...
    docker-compose up -d --build
    IF %ERRORLEVEL% NEQ 0 (
        echo Docker build/start failed!
        exit /b %ERRORLEVEL%
    ) ELSE (
        echo NiFi should be available shortly at https://nifi:8443/nifi
    )
)
