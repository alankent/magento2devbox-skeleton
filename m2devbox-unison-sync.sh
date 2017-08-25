#!/bin/bash

if [[ ! -f unison ]]; then
    echo "The unison binary could not be found. You can retrieve a"
    echo "compatible version from the DevBox web container using:"
    echo ""
    echo "   docker cp proj1-m2web:/mac-osx/unison ."
    echo "   docker cp proj1-m2web:/mac-osx/unison-fsmonitor ."
    echo "   chmod +x unison unison-fsmonitor"
    echo ""
    exit 1
fi

# Fetch the external Docker Unison port number
UNISON_PORT=$(docker-compose port web 5000 | awk -F: '{print $2}')

LOCAL_ROOT=./shared/www
REMOTE_ROOT=socket://localhost:$UNISON_PORT//var/www

IGNORE=

# Magento files not worth pulling locally.
IGNORE="$IGNORE -ignore 'Path magento2/var/cache'"
IGNORE="$IGNORE -ignore 'Path magento2/var/composer_home'"
IGNORE="$IGNORE -ignore 'Path magento2/var/log'"
IGNORE="$IGNORE -ignore 'Path magento2/var/page_cache'"
IGNORE="$IGNORE -ignore 'Path magento2/var/session'"
IGNORE="$IGNORE -ignore 'Path magento2/var/tmp'"
IGNORE="$IGNORE -ignore 'Path magento2/var/.setup_cronjob_status'"
IGNORE="$IGNORE -ignore 'Path magento2/var/.update_cronjob_status'"
IGNORE="$IGNORE -ignore 'Path magento2/pub/media'"
IGNORE="$IGNORE -ignore 'Path magento2/pub/static'"

# Other files not worth pushing to the container.
IGNORE="$IGNORE -ignore 'Path magento2/.git'"
IGNORE="$IGNORE -ignore 'Path magento2/.gitignore'"
IGNORE="$IGNORE -ignore 'Path magento2/.gitattributes'"
IGNORE="$IGNORE -ignore 'Path magento2/.magento'"
IGNORE="$IGNORE -ignore 'Path magento2/.idea'"
IGNORE="$IGNORE -ignore 'Name {.*.swp}'"
IGNORE="$IGNORE -ignore 'Name {.unison.*}'"

UNISONARGS="$LOCAL_ROOT $REMOTE_ROOT -prefer $LOCAL_ROOT -preferpartial 'Path var -> $REMOTE_ROOT' -auto -batch $IGNORE"

if [[ ! -f $LOCAL_ROOT/magento2/vendor ]]; then
   echo "**** Pulling files from container (faster quiet mode) ****"
   ./unison $UNISONARGS -silent 1>/dev/null 2>&1 
fi

while true; do
    echo "**** Entering file watch mode ****"
    ./unison $UNISONARGS -repeat watch
    sleep 5
done
