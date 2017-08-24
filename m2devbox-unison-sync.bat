REM @ECHO OFF

IF NOT EXIST unison.exe (
    @ECHO The unison.exe binary could not be found. You can retrieve a
    @ECHO compatible version from the DevBox web container using:
    @ECHO docker cp m2web:/windows/unison.exe .
    @ECHO docker cp m2web:/windows/unison-fsmonitor.exe .
    GOTO exit
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
@SET IGNORE=%IGNORE% -ignore "Path var/cache"
@SET IGNORE=%IGNORE% -ignore "Path var/composer_home"
@SET IGNORE=%IGNORE% -ignore "Path var/log"
@SET IGNORE=%IGNORE% -ignore "Path var/page_cache"
@SET IGNORE=%IGNORE% -ignore "Path var/session"
@SET IGNORE=%IGNORE% -ignore "Path var/tmp"
@SET IGNORE=%IGNORE% -ignore "Path var/.setup_cronjob_status"
@SET IGNORE=%IGNORE% -ignore "Path var/.update_cronjob_status"
@SET IGNORE=%IGNORE% -ignore "Path pub/media"
@SET IGNORE=%IGNORE% -ignore "Path pub/static"
@SET IGNORE=%IGNORE% -ignore "Path app/etc/env.php"

REM Other files not worth pushing to the container.
@SET IGNORE=%IGNORE% -ignore "Path .git"
@SET IGNORE=%IGNORE% -ignore "Path .gitignore"
@SET IGNORE=%IGNORE% -ignore "Path .gitattributes"
@SET IGNORE=%IGNORE% -ignore "Path .magento"
@SET IGNORE=%IGNORE% -ignore "Path .idea"
@SET IGNORE=%IGNORE% -ignore "Path unison.exe"
@SET IGNORE=%IGNORE% -ignore "Path unison-fsmonitor.exe"
@SET IGNORE=%IGNORE% -ignore "Name {.*.swp}"
@SET IGNORE=%IGNORE% -ignore "Name {.unison.*}"

@set UNISONARGS=%LOCAL_ROOT% %REMOTE_ROOT% -prefer %LOCAL_ROOT% -preferpartial "Path var -> %REMOTE_ROOT%" -auto -batch %IGNORE%

REM *** Check for sync readiness ***
SET loopcount=1000
:loop_sync_ready
    IF EXIST ./shared/state/enable_sync GOTO exitloop_sync_ready
    TIMEOUT 5
    @SET /a loopcount=loopcount-1
    @IF %loopcount%==0 GOTO exitloop_sync_ready
    @GOTO loop_sync_ready
:exitloop_sync_ready

IF NOT EXIST  %LOCAL_ROOT%/vendor (
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