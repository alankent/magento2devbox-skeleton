# Introduction

This repository is part of the Magento DevBox project, a Magento 2 development
environment. This is NOT intended for production usage.

Please note, a previous version of DevBox included a web site with GUI to
preconfigure your installation. While useful to get going, developers still
needed to understand the underlying commands. The new DevBox has less 'magic',
resulting in these instructions being longer, but developers having more
control.

## General Operation

DevBox contains all the the software packages you need to develop a Magento
site, except for IDEs and web browsers. A local development environment
typically starts with a database container (holding MySQL) and a web server
container (holding the Magento source code). Other containers can be added as
required for Varnish (recommended), Redis, RabbitMQ, and ElasticSearch. All
containers run Linux inside.

Developers mainly interact with the web container. The other containers are
relatively shrink wrap.

Normally you set up containers and use them for a long time, removing them only
when no longer required. Containers can be 'stopped' without being 'removed' to
save CPU and memory resources while not in use.

## File Syncing

Mac and Windows cannot directly access the file system inside the web container
(Linux can). This has a number of implications.

* Most developers prefer to use a IDE such as PHP Storm for development. PHP
  Storm has special support for "remote PHP interpeters" via ssh. This makes
  source code development and debugging using PHP Storm relatively painless
  even when PHP and the web server are running inside a Docker container.
  However, PHP Storm does need access to the the source code for editing and
  debugging.

* There are several directories (such as log directories) which you can choose
  to mount via Docker volumes for easy access directly from your laptop. These
  files are generally small in number and size for which Docker volume mounting
  works fine. By default the volume mounts are commented out in the
  `docker-compose.yml` file for improved performance.

* Some frontend developer tools like Gulp and Grunt rely on file watching
  "iNotify" file system events. Docker Volume mounting on Windows does not
  support iNotify events at this time.

Where volume mounts are not suitable (specifically, the Magento source code
directory on Mac and Windows), DevBox syncs the local and container file
systems using a program called Unison. Whenever a file in the watched local file
system is changed, it is copied into the web container, and vice versa. This
allows IDEs to be natively used on a laptop (or desktop) - Unison copies file
changes as soon as they are written to disk into the web conatiner.

# Installation

Now you understand what file syncing approach you are going to use, you are now
ready to get up and going with DevBox.

## Prerequisites

* Install a recent version of Docker from http://docker.com/. Docker is
  available for Windows, Mac, and Linux. 
* As part of the Docker installation process on Windows 10, you may need to
  turn on Hyper-V and then grant Docker access to the `C:` drive for Docker to
  mount volumes correctly. This is described in the Docker documentation.
* On Windows, it can be useful to install "Git Bash"
  (https://git-for-windows.github.io/). As well as Git, it includes SSH, an
  xterm terminal emulator, and a useful collection of commonly used Linux
  commands.

## Setting Up a New Environment

### 1. Create a Local Project Directory

Create a new directory per project. Use a meaningful directory name as it is
also used as a prefix for DevBox containers. Download a copy of the files in
this GitHub repository to the project directory.

  * Go to http://github.com/alankent/magento2devbox-skeleton
  * In the "Branch" drop down, select the tag closest to the project's version
    of Magento. This is to get the correct version of PHP, MySQL, etc.
    If in doubt, pick "master" (the default).
  * Click on the green button "Clone or Download" and select "Download ZIP".
  * Extract the ZIP file contents into the project directory.

### 2. Review and Update the docker-compose.yml File

Review the `docker-compose.yml` file in a text editor, making necessary
adjustments as described by comments in the file. This includes:

* To enable volume mounting for the Magento source code (e.g. for Linux
  laptops), uncomment the volume mount line for `/var/www` in the provided
  `docker-compose.yml` file. For Unison (e.g. for Mac and Windows), ensure the
  line is commented out.

* Check the port numbers. By default Docker will allocate random free port
  numbers. Change "80" to "8080:80" if you want the web server port to be
  always 8080. You cannot run different containers at the same time using
  the same port numbers.

* The recommended way to create and update projects is via Composer, a PHP
  package manager. Magento provides a Composer repository from which Magento
  (and extensions purchased from Magento Marketplace) can be downloaded.
  Composer caches downloads for performance. Mounting the cache directory on
  your laptop is enabled by uncommenting the "~/.composer" volume mount in the
  `docker-compose.yml` file. This allows downloads to be shared between
  containers (e.g. on different projects). If you do not mount a directory, the
  cache will discarded when the container is removed.

* Add your keys as web service environment variables if you want to share these
  keys easily with other developers on the same project. (You can share the
  `docker-compose.yml` to ensure a consistent setup between team members.)

* If you plan to use Varnish caching, uncomment the appropriate lines to create
  the Varnish container. A common source of production web caching defects is
  the lack of testing with Varnish during development.

* Similarly, if you plan to use Redis, ElasticSearch, or RabbitMQ in
  production, uncomment the appropriate lines so you can test during
  developement.

### 3. Launch the Containers

Launch the containers by changing to the project directory and then running:

    docker-compose up -d

You can check what containers exist using

    docker ps -a

To get a bash prompt inside the a container, use

    docker-compose exec --user magento2 web bash

This example specified the 'web' service container (see `docker-compose.yml`
for the other service names). You should see a shell prompt of `m2$`. If you
are using a Git Bash window on Windows, you may see an error message saying you
need to use `winpty`. In that case you must use the following command.

    winpty docker-compose exec --user magento2 web bash

In general this works well, but on Windows the 'exec' command will exit if you
press CTRL+Z. If you like using CTRL+Z in Linux, this is rather annoying, so
SSH access is recommended instead. SSH is currently only supported in the 'web'
service container.

The `m2ssh` BAT and bash scripts automatically pick up the port number from the
`docker-compose.yml` file and logs on to the 'magento2' account.

    m2ssh

If you are running Docker in VirtualBox, you may need to edit the local `m2ssh`
and `m2unison` scripts to replace "localhost" with the IP address allocated by
VirtualBox.

### 4. Install Magento

Next you need to install your Magento project inside the web container under
the `/var/www/magento2` directory. (Apache is configured by default to use
`/var/www/magento2` as the document root.) There are multiple options here.

Note: The first time you run Composer in the following steps, it may prompt you
for a username and password. Enter your 'public' and 'private' keys from
http://marketplace.magento.com/, "My Profile", "Access keys" when prompoted. Be
aware that an `auth.json` file holding your keys will be saved into
`~/.composer/`. If you want to share the Composer downloaded files but have a
different `auth.json` file per project, move the `auth.json` file into your
project's home directory. Most people add this file to their `.gitignore` file
to help restrict access to the download keys.

**Existing Project**

If you have an existing project with all the source code already under
`shared/www` on your laptop, no additional configuration is needed. If you use
volume mounting, the code will automatically be visible; if you use Unison,
Unison will copy files on your laptop into the web container when it is
started.

**Creating a New Project with Composer**

Log into the web container.

    m2ssh

Create a new project under `/var/www/magento2`. Update the project edition and
version number as appropriate. This example uses Magento Open Source (formerly
"Community Edition") version 2.1.8. (`xdebug-off` is a convenient shell script
in the `~/bin` directory to turn of XDebug support. XDebug significantly slows
down Composer.)

    cd /var/www/magento2
    xdebug-off
    composer create-project --repository=https://repo.magento.com/ magento/project-community-edition:2.1.8 .
    chmod +x bin/magento

**Getting Code from a GitHub Project**

It is strongly recommended to saving your project code in a private git
repository on a hosting provider such as GitHub or BitBucket.

Log into the web container:

    m2ssh

Check out the project from inside the container into the `magento2` directory.

    cd /var/www
    rm -rf magento2
    git clone https://github.com/mycompany/myproject.git magento2
    cd magento2
    xdebug-off
    composer install

**Magento Commerce (Cloud)**

TODO

**Internal Development**

TODO: THIS SECTION IS INDICATIVE OF FUTURE DIRECTION, NOT SUPPORTED YET.

This section is ONLY relevant to internal Magento developers, or external
developers wishing to submit a pull request. The following is NOT recommended
for production sites. (It may however be worth exploring by extension
developers.)

Log into the web container:

    m2ssh

Make a local clone of Magento Open Source (formerly Community Edition). Use
your own fork repository URL if appropriate.

    cd /var/www
    git clone https://github.com/magento/magento2.git
    cd magento2
    xdebug-off
    composer install

Clone any other projects such as Magento Commerce (formerly Enterprise Edition)
or the B2B code base, if you have appropriate permissions.

    cd /var/www
    git clone https://github.com/magento/magento2ee.git
    cd magento2
    xdebug-off
    composer require ...TODO...

### 5. Create the Database

The MySQL container by default does not have a database created for Magento
to use. The following creates the database `magento2`.

Log on to the bash prompt inside the web container

    m2ssh

Run the following commands to create a MyQL database for the web site to use
(plus a second database for integration tests to use).

    mysql -e 'CREATE DATABASE IF NOT EXISTS magento2;'
    mysql -e 'CREATE DATABASE IF NOT EXISTS magento_integration_tests;'

After the database is created, uncomment the line setting the default
database in the MySQL `~/.my.cnf` file.

    sed -e 's/#database/database/' -i ~/.my.cnf

The `mysql` command can now be used without arguments or selecting database.

    mysql
    > SHOW TABLES;
    > exit;

Set up all the Magento 2 tables with the following command (adjusting command
line parameter values as desired). (See below for extra arguments if you wish
to use RabbitMQ as well.)

    magento setup:install --db-host=db --db-name=magento2 --db-user=root --db-password=root --admin-firstname=Magento --admin-lastname=Administrator --admin-email=user@example.com --admin-user=admin --admin-password=admin123 --language=en_US --currency=USD --timezone=America/Chicago --use-rewrites=1 --backend-frontname=admin

It is recommended to NOT include the `--base_url` option during development as
Docker can allocate a port number at random (including when container is
restarted). It also causes problems using BrowserSync and similar tools for
frontend development. Some versions of Magento however have a bug requiring
`--base_url` to be specified. If the URL to CSS files is incorrect, you may
have a broken version of Magento.

If you are using RabbitMQ (AMPQ), the following command line arguments should
be added when the project was created above.

    --amqp-virtualhost=/ --ampq-host=ampq --amqp-port=TODO --amqp-user=guest --amqp-password=guest

**Loading Optional Sample Data**

To download the Luma sample data, you may need to provide Composer
authentication details. If you already have a `~/.composer/auth.json` file you
can run

    COMPOSER_AUTH=$(cat ~/.composer/auth.json) magento sampledata:deploy

Otherwise run the following command and enter your public and private keys when
prompted.

    magento sampledata:deploy

To load the sample data into the database, run

    magento setup:upgrade

### 6. Put Site into Developer Mode

Put the site into developer mode. Turning on xdebug is useful for debuging
purposes, but makes all PHP scripts slower to execute.

    magento deploy:mode:set developer
    xdebug-on

### 7. Start Unison, if Needed

If you are using Unison for file syncing, you also need to start up a Unison
process (and keep it running). It is generally recommended to start this up
after you have installed Magento above.

On Windows, run the supplied BAT file to launch Unison in a separate window
using the START command or by double clicking the BAT file via Windows file
explorer. This will automatically retrieve a copy of the `unison.exe` binary
from the web container. Close the window to kill Unison.

    START m2unison.bat

Mac binaries and a shell script are also provided. It is recommended to run the
sync shell script in a separate Terminal window so you can refer to its output
if you ever need to do troubleshooting.

    ./m2unison

This shell script cannot be used on Linux, only Mac OSX. Use volume mounting on
Linux (not Unison).

Each time you log in, make sure you restart Unison, but be careful to not have
multiple copies running in parallel. It is not recommended to do significant
work on the project without Unison running to avoid merge conflicts (rare).

### 8. Cron

Cron is disabled by default. Running cron may result in faster draining of
laptop batteries. To manually trigger background index updates, run `magento
cron:run` twice in a row (sometimes the first cron schedules jobs for the
second cron to run).

    magento cron:run
    magento cron:run

TODO: VERIFY TWO RUNS ARE NEEDED FIRST TIME ONLY. IF SO, CAN SIMPLIFY HERE.

To enable cron permanently run the following shell script.

    cron-install

### 9. Connect with a Web Browser

Run the following command to determine the web server port number to use when
connecting to the web service container. (This can be different to the port
number used inside the container.)

    docker-compose port web 80

If the response is, for example, port 8080, connect to the web server store
front using

    http://localhost:8080/

Connect to the Magento Admin by appending `/admin` with username "admin" and
password "admin123" (from the earlier `magento setup:install` command)

    http://localhost:8080/admin

If you are running Docker inside VirtualBox, replace "localhost" with the IP
address VirtalBox allocated to the VM Docker is running within.

Be aware that in developer mode the slower PHP debug mode is on and missing
CSS and similar files are created on demand. This means the first time you
load a page you will see significantly longer load times.

### 10. Configure PHP Storm (if appropriate)

TODO: Script? SSH and Remote Interpreters?

### 11. Varnish Configuration

TODO: THIS SECTION IS NOT COMPLETE.

Varnish is a "HTTP accelerator" that sits in front the web server and caches
content of HTTP responses. It is recommended to use Varnish during development
to help identify caching issues as early as possible.

To enable Varnish, run the following command. This updates configuration
settings in the database.

TODO: NEED TO TRY THIS OUT AND TEST WITH VARNISH CONTAINER ETC.

    varnish-install
    # magento config:set --scope=default --scope-code=0 system/full_page_cache/caching_application 2

To connect via your web browser to Varnish, you must use the Varnish port
number instead of the web server port number. To determine the Varnish port
number, use

TODO: WHY 6081? WHY NOT PORT 80? DEVDOCS MENTIONED PORT 6082 AS WELL.

    docker-compose port varnish 6081

### 12. Redis Configuration

Uncomment the Redis service in the `docker-compose.yml` if you wish to use
Redis during development, keeping your local development environment closer to
your production setup. Redis is recommended if you have a cluster of web
servers in production as an efficient way to share state (such as current
session information) between them.

The Magento DevDocs site (http://devdocs.magento.com/) describes how to
configuration Redis. The following instructions summarize the steps for
Magento 2.2 onwards.

To turn on usage of Redis for session caching, run

    magento setup:config:set --session-save=redis --session-save-redis-host=redis --session-save-redis-log-level=3 --session-save-redis-timeout=10

To turn on usage of Redis for default data caching, run

    magento setup:config:set --cache-backend=redis --cache-backend-redis-server=redis --cache-backend-redis-db=1

To turn on usage of Redis for page caching (not needed if using Varnish), run

    magento setup:config:set --page-cache=redis --page-cache-redis-server=redis --page-cache-redis-db=2

### 13. Grunt and Gulp Configuration

Grunt and Gulp are both frontend tool chains to speed up frontend development.
They can both auto-recompile CSS files as soon as a file is written to disk.
NodeJS is preinstalled in the web service container for use by Grunt and Gulp,
along with grunt-cli, gulp-cli, and browsersync.

To enable Grunt support, run the following commands

    cd /var/www/magento2
    cp Gruntfile.js.sample Gruntfile.js
    cp package.json.sample package.json
    npm install
    grunt refresh --force
    grunt watch

For further details, please refer to the Grunt section in the "Frontend
Developer Guide" on http://devdocs.magento.com/.

Magento does not ship with Gulp support, but there are numerous articles on the
web explaining how to use Gulp with Magento 2, such as
https://alankent.me/2016/01/27/gulp-et-al-in-magento-2/. 

If you wish to run BrowserSync (https://www.browsersync.io/), with Gulp you
need to ensure the BrowserSync ports (3000 and 3001) are left uncommented in
the `docker-compose.yml` file.

# Developing Your Own Module or Extension

This section contains suggested ways in which you can manage modules or
extensions that are being developed in a separate git repository to your main
project. For example, a system integrator may wish to share a set of locally
developed modules across multiple customers.

## Single Module Projects

Composer has special support when there is one module per git repository.
Composer can perform a git clone of the code automatically, where the code ends
up under the `vendor` directory, like other downloaded modules, but you can
edit and change the source code and commit your changes afterwards.

In this mode, you create your module in git first, then run the following
commands to update the composer.json file.

First add a repository entry for the git repository, replacing "myvendor" and
"mymodule" with your vendor and module name.

    composer config repositories.mymodule vcs git@github.com:myvendor/module-mymodule.git

Next, add the dependency on your module. A version number with the form of
"dev-{branch}" checks out that branch from the git repository.

    composer require --prefer-source myvendor/module-mymodule:dev-master

Refer to the Composer documentation for more details and variations supported.

## Multi-Module Projects

If you want to keep multiple modules in one git repo (so they version
together), a different approach is required. Note this can also be used for git
repositories containing a single module if desired.

First, check out your git repository under `/var/www` (alongside the `magento2`
directory).

    cd /var/www
    git clone git@github.com:myvendor/myrepo.git

Next, add a repository reference to all the directories containing packages
(that is, all directories containing a `composer.json` file). You may use `*`
in path wildcards to include multiple directories at a time. Make sure you use
quotes to make sure the shell does not expand the wildcards.

    composer config repositories.myrepo path "../myrepo/app/*/myvendor/*"

You can then add dependencies to any of the packages in the specified
directories. Composer will create a symlink from under the `vendor/myvendor`
directory to the appropriate git repository directory.

    composer require myvendor/module-mymodule:*

Note that while Unison will not sync the symlink, if you specify the
`shared/www` local directory as the "source code root" in PHP Storm, it will
find the PHP code under both `/var/www/magento2` and `/var/www/myrepo`.

# Tips and Tricks

The following can be useful tips and tricks.

## Other Docker Commands

To see what containers are running, use

    $ docker ps -a

To stop the containers when not in use, use

    $ docker-compose stop

If you are using Unison, it is generally recommended to exit it as well.

Restart the containers later with

    $ docker-compose start

If you are using Unison, remember to also restart Unison for file syncing
to work.

## Removing and Rebuilding Containers

When you no longer need the DevBox, you can kill and remove all of the running
containers. THIS WILL WIPE ALL FILES INSIDE THE WEB CONTAINER AND THE DATABASE,
LOSING ANY CHANGES FOREVER. It will not remove any locally synchronized files
under the `shared` directory.

    docker-compose kill
    docker-compose rm

If you decide to change the settings in `docker-composer.yml` after the
containers have been created, you will need to rebuild the containers.
MAKE SURE THE SOURCE CODE IS UP TO DATE UNDER THE `shared/www` DIRECTORY ON
YOUR LAPTOP BEFORE REBUILDING THE CONTAINERS TO MAKE SURE YOU DO NOT
ACCIDENTALLY LOSE ANY OF YOUR WORK.

There are two strategies you can use. The first is to delete all the containers
as above and then recreate them. This will delete the database contents as
well.

    docker-compose kill
    docker-compose rm
    # Make changes to docker-compose.yml
    docker-compose up -d

If you are using Unison file syncing, when you restart Unison locally it will
copy all the code from `shared/www` back into the `/var/www` directory inside
the container. After that, `magento setup:install` can be run to rebuild the
database.

The second approach is to use the `--build` option of Docker Compose which
will only rebuild affected containers. For example, if opening up a new port
to the web service container, using `--build` will not remove the database
container, preserving its contents. When the `/var/www` directory is restored
(via Unison or Volume mounting) the database connection settings (in `env.php`)
will also be restored.

    # Make changes to docker-compose.yml
    docker-compose up -d --build

## Kitematic

If you like GUIs, you may wish to install Kitematic from the Docker site as
well. It provides a GUI to manage Docker containers. Kitematic does not
understand Docker Compose, only individual containers.

You can use Docker command line commands in combination with Kitematic to
manage containers, but sometimes Kitematic will not notice command line
changes, requiring Kitematic to be exited and restarted to refresh the
container list it is aware of.

## Other Magento Commands

To flush various caches:

    magento cache:flush

Tell any configured external caches (e.g. Redis) to clean themselves.

    magento cache:clean

Run shell script to remove all generated files and clean all caches.

    clean-generated

To run cron by hand if not running automatically (run this twice to gurantee
all jobs are queued and run).

    magento cron:run

To check module statuses

    magento module:status

To disable/enable a module

    magento module:disable Magento_Customer
    magento module:enable Magento_Customer

To rebuild indexes

    magento indexer:reindex

