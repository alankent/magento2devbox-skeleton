@ECHO OFF

REM Set to '1' to use direct socket, '0' for SSH.
REM Note: Some have reported occasional hangs using socket, SSH has been more
REM reliable. 
SET USE_SOCKET=0

IF "%USE_SOCKET" == "1" GOTO skipssh
    REM Fetch the external Docker SSH port number
    FOR /f "delims=" %%A IN ('docker-compose port unison 22') DO SET "CMD_OUTPUT=%%A"
    FOR /f "tokens=1,* delims=:" %%A IN ("%CMD_OUTPUT%") DO SET "SSH_PORT=%%B"
    REM Run SSH to allow user to accept the fingerprint on first connection.
    ssh -p %SSH_PORT% magento2@localhost echo SSH connection established
:skipssh

SET PROJ=%COMPOSE_PROJECT_NAME%
IF [%PROJ%] == [] (
    REM Get current directory name.
    FOR %%a IN (.) DO SET PROJ=%%~nxa
)

IF NOT EXIST unison.exe (
    REM **** Getting unison.exe binary from unison container.
    docker cp %PROJ%_unison_1:/windows/unison.exe .
    docker cp %PROJ%_unison_1:/windows/unison-fsmonitor.exe .
)

REM Add Windows\system32 to start of path to find the right "timeout" command
REM Cygwin can end up with 'unix like' timeout in path instead otherwise
PATH C:\Windows\System32;%PATH%

SET LOCAL_ROOT=./shared/www

SET IGNORE=

REM Magento files not worth pulling locally.
SET IGNORE=%IGNORE% -ignore "Path magento2/var/cache"
SET IGNORE=%IGNORE% -ignore "Path magento2/var/composer_home"
SET IGNORE=%IGNORE% -ignore "Path magento2/var/log"
SET IGNORE=%IGNORE% -ignore "Path magento2/var/page_cache"
SET IGNORE=%IGNORE% -ignore "Path magento2/var/session"
SET IGNORE=%IGNORE% -ignore "Path magento2/var/tmp"
SET IGNORE=%IGNORE% -ignore "Path magento2/var/.setup_cronjob_status"
SET IGNORE=%IGNORE% -ignore "Path magento2/var/.update_cronjob_status"

REM Other files not worth pushing to the container.
SET IGNORE=%IGNORE% -ignore "Path magento2/.git"
SET IGNORE=%IGNORE% -ignore "Path magento2/.gitignore"
SET IGNORE=%IGNORE% -ignore "Path magento2/.gitattributes"
SET IGNORE=%IGNORE% -ignore "Path magento2/.magento"
SET IGNORE=%IGNORE% -ignore "Name {.idea}"
SET IGNORE=%IGNORE% -ignore "Name {.*.swp}"
SET IGNORE=%IGNORE% -ignore "Name {.unison.*}"

IF "%USE_SOCKET%" == "1" GOTO usesock1
    REM Fetch the external Docker SSH port number
    FOR /f "delims=" %%A IN ('docker-compose port unison 22') DO SET "CMD_OUTPUT=%%A"
    FOR /f "tokens=1,* delims=:" %%A IN ("%CMD_OUTPUT%") DO SET "SSH_PORT=%%B"
    SET REMOTE_ROOT=ssh://magento2@localhost//var/www
    SET SSH_ARGS=-p %SSH_PORT%
GOTO done1
:usesock1
    REM Fetch the external Docker Unison port number
    FOR /f "delims=" %%A IN ('docker-compose port unison 5000') DO SET "CMD_OUTPUT=%%A"
    FOR /f "tokens=1,* delims=:" %%A IN ("%CMD_OUTPUT%") DO SET "UNISON_PORT=%%B"
    SET REMOTE_ROOT=socket://localhost:%UNISON_PORT%//var/www
:done1

SET UNISONARGS=%LOCAL_ROOT% %REMOTE_ROOT% -sshargs "%SSH_ARGS%" -prefer %LOCAL_ROOT% -preferpartial "Path var -> %REMOTE_ROOT%" -auto -batch %IGNORE% 

IF NOT EXIST %LOCAL_ROOT%/magento2/vendor (
   @ECHO ON
   REM **** Pulling files from container (faster quiet mode) ****
   .\unison %UNISONARGS% -silent >NUL:
   @ECHO OFF
)

@ECHO ON
REM **** Entering file watch mode ****
@ECHO OFF
:loop_sync
    @ECHO ON
    .\unison %UNISONARGS% -repeat watch
    TIMEOUT 5
    @ECHO OFF

    REM Re-fetch the external Docker port number in case it changed.
    IF "%USE_SOCKET%" == "1" GOTO usesock2
        REM Fetch the external Docker SSH port number
        FOR /f "delims=" %%A IN ('docker-compose port unison 22') DO SET "CMD_OUTPUT=%%A"
        FOR /f "tokens=1,* delims=:" %%A IN ("%CMD_OUTPUT%") DO SET "SSH_PORT=%%B"
        SET REMOTE_ROOT=ssh://magento2@localhost//var/www
        SET SSH_ARGS=-p %SSH_PORT%
    GOTO done2
    :usesock2
        REM Fetch the external Docker Unison port number
        FOR /f "delims=" %%A IN ('docker-compose port unison 5000') DO SET "CMD_OUTPUT=%%A"
        FOR /f "tokens=1,* delims=:" %%A IN ("%CMD_OUTPUT%") DO SET "UNISON_PORT=%%B"
        SET REMOTE_ROOT=socket://localhost:%UNISON_PORT%//var/www
    :done2

    set UNISONARGS=%LOCAL_ROOT% %REMOTE_ROOT% -sshargs "%SSH_ARGS%" -prefer %LOCAL_ROOT% -preferpartial "Path var -> %REMOTE_ROOT%" -auto -batch %IGNORE%

    @ECHO ON
    REM **** Unison exited - Restarting file watch mode ****
    @ECHO OFF

GOTO loop_sync

PAUSE
