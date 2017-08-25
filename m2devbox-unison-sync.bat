REM @ECHO OFF

@SET PROJ=%COMPOSE_PROJECT_NAME%
@IF [%PROJ%] == [] (
    REM Get current directory name.
    FOR %%a IN (.) DO SET PROJ=%%~nxa
)

IF NOT EXIST unison.exe (
    REM **** Getting unison.exe binary from web container.
    docker cp %PROJ%_web_1:/windows/unison.exe .
    docker cp %PROJ%_web_1:/windows/unison-fsmonitor.exe .
)

REM Add Windows\system32 to start of path to find the right "timeout" command
REM Cygwin can end up with 'unix like' timeout in path instead otherwise
PATH C:\Windows\System32;%PATH%

REM Fetch the external Docker Unison port number
FOR /f "delims=" %%A IN ('docker-compose port web 5000') DO SET "CMD_OUTPUT=%%A"
FOR /f "tokens=1,* delims=:" %%A IN ("%CMD_OUTPUT%") DO SET "UNISON_PORT=%%B"

@SET LOCAL_ROOT=./shared/www
@SET REMOTE_ROOT=socket://localhost:%UNISON_PORT%//var/www

@SET IGNORE=

REM Magento files not worth pulling locally.
@SET IGNORE=%IGNORE% -ignore "Path magento2/var/cache"
@SET IGNORE=%IGNORE% -ignore "Path magento2/var/composer_home"
@SET IGNORE=%IGNORE% -ignore "Path magento2/var/log"
@SET IGNORE=%IGNORE% -ignore "Path magento2/var/page_cache"
@SET IGNORE=%IGNORE% -ignore "Path magento2/var/session"
@SET IGNORE=%IGNORE% -ignore "Path magento2/var/tmp"
@SET IGNORE=%IGNORE% -ignore "Path magento2/var/.setup_cronjob_status"
@SET IGNORE=%IGNORE% -ignore "Path magento2/var/.update_cronjob_status"
@SET IGNORE=%IGNORE% -ignore "Path magento2/pub/media"
@SET IGNORE=%IGNORE% -ignore "Path magento2/pub/static"

REM Other files not worth pushing to the container.
@SET IGNORE=%IGNORE% -ignore "Path magento2/.git"
@SET IGNORE=%IGNORE% -ignore "Path magento2/.gitignore"
@SET IGNORE=%IGNORE% -ignore "Path magento2/.gitattributes"
@SET IGNORE=%IGNORE% -ignore "Path magento2/.magento"
@SET IGNORE=%IGNORE% -ignore "Path magento2/.idea"
@SET IGNORE=%IGNORE% -ignore "Name {.*.swp}"
@SET IGNORE=%IGNORE% -ignore "Name {.unison.*}"

@set UNISONARGS=%LOCAL_ROOT% %REMOTE_ROOT% -prefer %LOCAL_ROOT% -preferpartial "Path var -> %REMOTE_ROOT%" -auto -batch %IGNORE%

IF NOT EXIST  %LOCAL_ROOT%/magento2/vendor (
   REM **** Pulling files from container (faster quiet mode) ****
   .\unison %UNISONARGS% -silent >NUL:
)

REM **** Entering file watch mode ****
:loop_sync
    .\unison %UNISONARGS% -repeat watch
    TIMEOUT 5
    @GOTO loop_sync

:exit
PAUSE
