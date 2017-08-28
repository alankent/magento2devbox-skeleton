@ECHO OFF

REM Fetch the external Docker SSH port number
FOR /f "delims=" %%A IN ('docker-compose port web 22') DO SET "CMD_OUTPUT=%%A"
FOR /f "tokens=1,* delims=:" %%A IN ("%CMD_OUTPUT%") DO SET "SSH_PORT=%%B"

REM Run SSH
ssh -p %SSH_PORT% magento2@localhost %*
