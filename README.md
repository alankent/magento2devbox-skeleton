# Introduction

This repository is part of the Magento DevBox project. The goal of this
project is to minimize the effort to set up a local development machine
(e.g. a laptop) for development of Magento 2 projects.

This project uses Docker, a containerization technology similar to Virtual
Machines. This allows developers to work on multiple projects concurrently,
which may need different versions of tools, without the pain of having to
install all those versions natively.

The environment is designed for development of Magento 2 projects - the
environment provided is not for production usage.

Please note, a previous version of DevBox included a web site with GUI to
preconfigure your installation. While useful to get going, developers still
needed to understand the underlying commands. The new DevBox has less 'magic',
resulting in these instructions being longer, but developers having more
control.

## General Operation

DevBox contains all the the software packages you need to develop a Magento
site, except for IDEs and web browsers. A local development environment
typically starts with a database container (holding MySQL) and a web server
container (holding the Magento source code). On Mac and Windows, another
container is used for file sharing (discussed below).  Other containers can be
added as required for Varnish (recommended), Redis, RabbitMQ, and
ElasticSearch. All containers run Linux inside.

Developers mainly interact with the web container. The other containers are
relatively shrink wrap. For example, some commands must be run by using ssh to
log into the web container.

Normally you set up containers and use them for a long time, removing them only
when no longer required. Containers can be 'stopped' without being 'removed' to
save CPU and memory resources while not in use. This is particularly useful
when you are working on multiple projects.

# Installation

This section walks you through how to install DevBox.

## 0. Prerequisites

* Install a recent version of Docker from http://docker.com/. Docker is
  available for Windows, Mac, and Linux. 
* On Windows 10, as part of the Docker installation process you may need to
  turn on Hyper-V and then grant Docker access to the `C:` drive for Docker to
  mount volumes correctly. This is described in the Docker documentation.
* On Windows, it is recommended to install "Git Bash"
  (https://git-for-windows.github.io/). This includes the git client, an ssh
  client, an xterm terminal emulator, and a useful collection of commonly used
  Linux commands. The following instructions assume you are using Git Bash.
* On Mac, install "Brew" (https://brew.sh/) if you have not done so already.

## 1. Create a Local Project Directory

Create a new directory per project. Use a short but meaningful directory name
as it is also used as a prefix for DevBox containers.

Download an initial set of files to the project directory.

  * Go to http://github.com/alankent/magento2devbox-skeleton
  * In the "Branch" drop down, select the tag closest to the project's version
    of Magento. This is to get the correct version of PHP, MySQL, etc.
    **[Note: this is a work in progress. Currently only "master" is avaialble.]**
  * Click on the green button "Clone or Download" and select "Download ZIP".
  * Extract the ZIP file contents into the project directory.

It is common to modify these downloaded files and delete unwanted files. For
example, on Mac feel free to delete any Windows BAT files.

## 2. Review and Update the docker-compose.yml File

The following steps set up the Docker configuration files before the containers
can be started.

Review the `docker-compose.yml` file in a text editor, making necessary
adjustments as described by comments in the file. This includes:

* Mac and Windows uses a utility called Unison to bi-directionally synchronize
  files between the Docker containers and the local file system. Unison is
  similar in concept to rsync, but more fully featured. To enable Unison,
  make sure the `/var/www` volume is uncommented and the
  `./shared/www:/var/www` line is commented out (or deleted). Make sure the
  "unison" service is also uncommented.

* For Linux, direct file sharing can be used if preferred. Make sure the
  `./shared/www:/var/www` line is uncommented and the `/var/www` line is
  commented out. Also comment out the "unison" service as it is not required.
  Direct file sharing is not recommended for Mac or Windows for performance
  reasons.

* Check the port numbers. By default Docker will allocate random free port
  numbers. Change ports such as "80" to "8080:80" if you want the web server
  port to be always 8080. You cannot run different containers at the same time
  using the same port numbers. On Mac, there is a default web server running on
  port 80 so you must use a different port number for the web server container.

* The recommended way to create and update projects is via Composer, a PHP
  package manager. Magento provides a Composer repository from which Magento
  (and extensions purchased from Magento Marketplace) can be downloaded.
  Composer caches downloads for performance. Mounting the cache directory on
  your laptop is enabled by uncommenting the "~/.composer" volume mount in the
  `docker-compose.yml` file. This allows downloads to be shared between
  containers (e.g. on different projects). If you do not mount a directory, the
  cache will discarded when the container is removed.

* Add your Magento Marketplace download access keys as web service environment
  variables if you want to share these keys easily with other developers on the
  same project. (You can share the `docker-compose.yml` to ensure a consistent
  setup between team members.) Otherwise Composer will prompt you for the keys
  later. Keys are available from https://marketplace.magento.com/. (Go to "My
  Profile", "My Purchases", "Access Keys".)

* If you plan to use Varnish during development, uncomment the appropriate
  lines to create the Varnish container. A common source of production defects
  is the lack of testing with Varnish during development. As such, some
  developers prefer to develop with Varnishing caching turned on to spot
  problems early.

* Similarly, if you plan to use Redis, ElasticSearch, or RabbitMQ in
  production, uncomment the appropriate lines so you can test during
  developement.

## 3. Launch the Containers

Launch the containers by changing to the project directory and then running:

    docker-compose up -d

You can check what containers exist using

    docker ps -a

To log into the web container, use the provided `m2ssh` BAT and bash scripts.
These automatically pick up the SSH port number from the `docker-compose.yml`
file and logs on to the 'magento2' account of the 'web' container.

    ./m2ssh

If you are running Docker in VirtualBox, you may need to edit the provided 
scripts to replace "localhost" with the IP address allocated by VirtualBox.

Note: If you destroy and recreate containers, SSH may report warnings about
changes in identity and refuse to connect. Use a text editor to remove
"localhost" lines from your `~/.ssh/known_hosts` file to overcome this issue
(you will then be prompted to accept new fingerprints on restart).

## 4. Start Unison (Mac, Windows)

If you are using Unison for file syncing the host and web container file system
(recommended on Mac and Windows), you also need to start up a Unison process
(and keep it running).

Each time you log to your laptop, make sure you restart Unison, but be careful
to not have multiple copies running in parallel. It is not recommended to do
significant work on the project without Unison running to avoid merge conflicts
(rare).

**Mac**

On Mac, first install Unison using "brew". This installs the correct command
line version of Unison. Also install "unox" for a companion file watching
utility.

    brew install unison
    brew tap eugenmayer/dockersync
    brew install eugenmayer/dockersync/unox

Use the provided shell script to start up Unison. This shell script creates
a Unison "profile" file in `~/.unison/m2devbox-{myproj}.prf` ({myproj}
is the current directory name) then starts up Unison in file watching mode.

    ./m2unison.sh

It is recommended to run Unison in a separate Terminal window so you can refer
to its output if you ever need to do troubleshooting. This is also useful when
synchronizing a large number of files for the first time to know when the copy
has completed.

If you ever restart the Docker containers, you may need to rerun `m2unison.sh`
to pick up any port number changes.

**Windows**

On Windows, run the supplied BAT file to launch Unison in a separate window
using the START command or by double clicking the BAT file via Windows file
explorer. This will automatically retrieve a copy of the `unison.exe` binary
from the web container. A profile is not required as the BAT file uses command
line arguments. Close the window to kill Unison.

    START m2unison.bat

Note: The shell script (`m2unison.sh`) is not intended for use on Windows.

## 5. Install Magento

Next you need to install your Magento project inside the web container under
the `/var/www/magento2` directory. (Apache is configured by default to use
`/var/www/magento2` as the document root.) There are multiple options here.

Note: The first time you run Composer in the following steps, it may prompt you
for a username and password. Enter your 'public' and 'private' keys from
http://marketplace.magento.com/, "My Profile", "Access keys" when prompoted. Be
aware that an `auth.json` file holding your keys will be saved into
`~/.composer/`. If you want to share the Composer downloaded files but have a
different `auth.json` file per project, move the `auth.json` file into your
project's home directory (`/var/www/magento2`). Most people add the `auth.json`
file to their `.gitignore` file to avoid accental sharing of the keys.

**Option 1: Existing Project**

If you have an existing set of project files, place them under the
`shared/www/magento2` directory on your laptop. If you use volume mounting, the
code will automatically be visible; if you use Unison, Unison will copy files
on your laptop into the web container when it is running. Also please note if
using Unison, symbolic links will not be copied into the container.

**Option 2: Creating a New Project with Composer**

Log into the web container.

    ./m2ssh

Create a new project under `/var/www/magento2` using the Composer
"create-project" command. Update the project edition and version number as
appropriate. This example uses Magento Open Source (formerly "Community
Edition") version 2.2.0.

    cd /var/www/magento2
    composer create-project --repository=https://repo.magento.com/ magento/project-community-edition:2.2.0 .
    chmod +x bin/magento

**Option 3: Getting Code from a GitHub Project**

It is strongly recommended to save your project code in a private git
repository on a hosting provider such as GitHub or BitBucket. The following
describes how a new environment can get the code from such an environment.

The first step is to decide whether you plan to run normally git on your laptop
or inside the container. Running it on the laptop is more frequent as many IDEs
have integrated git support

On your laptop, check out the project into the `magento2` directory.

    cd shared/www
    rm -rf magento2
    git clone https://github.com/mycompany/myproject.git magento2

Log into the web container:

    ./m2ssh

Use Composer to download all the additional needed packages.

    cd /var/www/magento2
    composer install

Alternatively, you can check out the project from inside the container if you
plan to run all your git commands there.

    cd /var/www
    rm -rf magento2
    git clone https://github.com/mycompany/myproject.git magento2
    cd magento2
    composer install

**Option 4: Magento Commerce (Cloud)**

TODO: WARNING: THIS SECTION IS NOT COMPLETE.

The following discussion is not a replacement for reading through the Magento
Commerce Cloud documentation on http://devdocs.magento.com/, but it summarizes
the main steps most users would take.

 1. Create your project using the Magento Cloud console.
 2. Make sure you have SSH keys set up to access the account. (See
    `magento-cloud ssh-keys` and `magento-cloud ssh-key:add`.) The
    `magento-cloud` CLI is preinstalled in the web service container.
 3. In the Magento Cloud console, click on "GIT" next to the "CLI" button to
    show the git command to check out the project's source code.
 4. Remove the default `magento2` directory.
 5. Check out the cloud git repo under the `magento2` directory. MAKE SURE YOU
    CHANGE THE LAST GIT ARGUMENT TO `magento2`.
 6. Run `composer install` to download all other dependencies.
 7. If you have any cloud patches you wish to use during development, run the
    `patch.php` file from the cloud configuration package.

The following is a sample session

    cd /var/www
    rm -rf magento2
    git clone --branch master 12myproj34@git.us.magento.cloud:12myproj34.git magento2
    cd magento2
    xdebug-off
    composer install
    php vendor/magento/magento-cloud-configuration/patch.php
    chmod +x bin/magento

Note that `magento-cloud get` is an alternative to the `git clone` command
above, but it is recommended to use `git` directly to check the code out into
the correct directory name (`/var/www/magento2`) as required by DevBox.

**Option 5: Internal Development**

TODO: THIS SECTION IS INDICATIVE OF FUTURE DIRECTION, NOT SUPPORTED YET.

This section is only relevant to internal Magento developers, or external
developers wishing to submit a pull request. The following is not recommended
for production sites. (It may however be worth exploring by extension
developers.)

Log into the web container:

    ./m2ssh

Make a local clone of Magento Open Source (formerly Community Edition). Use
your own fork repository URL if appropriate.

    cd /var/www
    rm -rf magento2
    git clone https://github.com/magento/magento2skeleton.git magento2

    git clone https://github.com/magento/magento2ce.git
    git clone https://github.com/magento/magento2ee.git
    git clone https://github.com/magento/magento2b2b.git

    cd magento2
    composer config repositories.ce path "../magento2ce/app/*/*/*"
    composer config repositories.ee path "../magento2ee/app/*/*/*"
    composer config repositories.b2b path "../magento2b2b/app/*/*/*"

    composer install

**Option 6: Recreating Docker Containers**

If you decide to remove and re-create the Docker containers, the existing code
will remain under `shared/www/magento2` on your laptop. These files will be
automatically picked up when the new set of containers are launched.

If using Unison, symbolic links are not copied. You may need to run
`composer install` inside the web container to recreate any symbolic links
required by Composer.

## 6. Create the Database

Magento DevBox runs MySQL in a separate database container. The MySQL
container by default does not have a database created for Magento to use. The
following creates the database `magento2`.

Log on to the bash prompt inside the web container

    ./m2ssh

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

It is recommended to NOT include the `--base-url` option during development as
Docker can allocate a port number at random (including when container is
restarted). It also causes problems using BrowserSync and similar tools for
frontend development. Some versions of Magento however have a bug requiring
`--base-url` to be specified. If the URL to CSS files is incorrect, you may
have a broken version of Magento. If this is the case, force the web server
port number be a specific port (e.g. use "8080:80" in `docker-composer.yml`)
and add the `--base-url` command line option (e.g. `--base-url=http://localhost:8080`).

TODO: I THINK YOU CAN RUN A SEPARATE COMMAND LATER. IF CORRECT, MOVE THIS TO A SEPARATE SECTION.
If you are using RabbitMQ (AMPQ), the following command line arguments should
be added when the project was created above.

    --amqp-virtualhost=/ --ampq-host=ampq --amqp-port=TODO --amqp-user=guest --amqp-password=guest

## 7. Loading Sample Data (Optional)

To download the Luma sample data, you may need to provide Composer
authentication details. If you already have a `~/.composer/auth.json` file you
can run

    COMPOSER_AUTH=$(cat ~/.composer/auth.json) magento sampledata:deploy

If you don't have a `~/.composer/auth.json` file, just run
`magento sampledata:deploy` and enter your public and private keys when
prompted.

To load the downloaded sample data into the database, run

    magento setup:upgrade

## 8. Cron (Optional)

Cron is disabled by default as running cron may result in faster draining of
laptop batteries. To manually trigger background index updates, run `magento
cron:run` twice in a row (sometimes the first cron schedules jobs for the
second cron to run).

    cd /var/www/magento2
    magento cron:run
    magento cron:run

To enable cron permanently (recommended) run the following command.

    cron-install

## 9. Put Site into Developer Mode

Magento supports developer and production modes. Production mode makes
optimizations assuming files on the site will not change. Developer mode is
suitable when making changes to a site during development.

    magento deploy:mode:set developer

## 10. Connect with a Web Browser

You are now ready to connect to your installation with a web browser.

If you did not specify a fixed port number in the `docker-composer.yml` file
for your site, run the following command to determine the web server port
number that was allocated to the web service container. (This is normally
different to the port number used inside the container.)

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
load a page you will see significantly longer load times. The more pages you
access, the faster the site will become.

## 11. Configure PHP Storm (Optional)

TODO: WARNING: THIS SECTION IS NOT COMPLETE.

PHP Storm is a popular IDE for PHP development. This section describes common
PHP Storm configuration settings for Magento 2 projects. PHP Storm has changed
(and will continue to change) over time, so the following instructions are
indicative only.

The following instructions assume the previous steps have already been
completed.

**Create New Project**

 1. Create a new project in PHP Storm using "Create New Project from Existing
    Files".
 2. Use the option "Source files are in local directory, no Web server is yet
    configured." (We will add the web server by hand later.)
 3. Select `shared/www` as the project root directory.
 4. Go to "File" / "Settings" to bring up the project's "Settings" diaglog box.
 5. Select "Directories" in the Settings Diaglog side bar.
    Suggested settings are:
     * Mark the root directory as "Sources".
     * Mark `magento2/dev/tests` as "Tests".
     * Mark `magento2/dev/tests/integration/tmp` as "Excluded".
     * Mark `magento2/pub/static` as "Excluded". (This directory may not exist
       until you access the site, triggering its creation.)
     * Mark `magento2/var` as "Excluded".
     * Mark `magento2/vendor/magento/magento2-base` as "Excluded".
 6. Select "Editor" / "File Encodings" in the Settings Diaglog side bar.
     * Set "Project Encoding" to "UTF-8".
 7. Select "Languages & Frameworks" / "PHP" in the Settings Diaglog side bar.
     * Select "7" from the drop down list of PHP versions.
     * Click "..." next to "CLI Interpreter" to bring up a list of "CLI
       Interpreters".
     * Click "+" then "From Docker, Vagrant, VM, Remote".
     * Select "SSH Credentials". (You may try "Docker Composer" if you prefer,
       but it is more complicated to set up.) Use:
	- Enter `localhost` for the host name (or the IP address allocated by
	  VirtualBox if running Docker inside VirtualBox).
	- Enter the port number from `docker-compose port web 22` (e.g. 2222)
	  for the port number.
	- Enter `magento2` for the user name.
	- Select "Password" as the "Auth type".
	- Leave the password field blank.
	- Set the PHP executable path to `/usr/local/bin/php`.
 8. Select "Tools" / "SSH Terminal", and select the "Default Remote
    Interpreter" radio button.

## 12. Varnish Configuration (Optional)

TODO: WARNING: THIS SECTION IS NOT COMPLETE.

Varnish is a "HTTP accelerator" that sits in front the web server and caches
content of HTTP responses. It is recommended to use Varnish during development
to help identify caching issues as early as possible.

To enable Varnish, run the following command. This updates configuration
settings in the database.

    varnish-install
    # magento config:set --scope=default --scope-code=0 system/full_page_cache/caching_application 2

To connect via your web browser to Varnish, you must use the Varnish port
number instead of the web server port number. To determine the Varnish port
number, use

    docker-compose port varnish 6081

## 13. Redis Configuration (Optional)

Uncomment the Redis service in the `docker-compose.yml` if you wish to use
Redis during development, keeping your local development environment closer to
your production setup. Redis is recommended if you have a cluster of web
servers in production as an efficient way to share state (such as current
session information) between them.

The Magento DevDocs site (http://devdocs.magento.com/) describes how to
configuration Redis. The following instructions summarize the steps for
Magento 2.2 onwards.

To turn on usage of Redis for session caching, run

    cd /var/www/magento2
    rm var/session/*
    magento setup:config:set --session-save=redis --session-save-redis-host=redis --session-save-redis-log-level=3 --session-save-redis-timeout=10

To turn on usage of Redis for default data caching, run

    magento setup:config:set --cache-backend=redis --cache-backend-redis-server=redis --cache-backend-redis-db=1

To turn on usage of Redis for page caching (not needed if using Varnish), run

    magento setup:config:set --page-cache=redis --page-cache-redis-server=redis --page-cache-redis-db=2

## 14. ElasticSearch Configuration (Optional)

TODO

## 15. RabbitMQ Configuration (Optional)

TODO

## 16. Grunt and Gulp Configuration (Optional)

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

# Appendix 1: Developing Your Own Module or Extension

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
quotes to make sure the shell does not expand the wildcards. (The wildcard will
match directories such as modules in `app/code/Magento/*` and themes in
`app/design/MyVendor/*`.)

    composer config repositories.myrepo path "../myrepo/app/*/*/*"

If developing a module, set the minimum stability to `dev` (and set it back to
a stable level when going live). See the Composer documentation for more
options.

    composer config minimum-stability dev

You can then add dependencies to any of the packages in the specified
directories. Composer will create a symlink from under the `vendor/myvendor`
directory to the appropriate git repository directory.

    composer require "myvendor/module-mymodule:*"

Note that while Unison will not sync the symlink, if you specify the
`shared/www` local directory as the "source code root" in PHP Storm, it will
find the PHP code under both `/var/www/magento2` and `/var/www/myrepo`.

# Appendix 2: Tips and Tricks

The following can be useful tips and tricks.

## Other Docker Commands

To see what containers are running, use

    docker ps -a

To stop the containers when not in use, use

    docker-compose stop

If you are using Unison, it is generally recommended to exit it as well.

Restart the containers later with

    docker-compose start

If you are using Unison, remember to also restart Unison for file syncing
to work.

To get a bash prompt inside a container, use

    docker-compose exec --user magento2 web bash

If you are using a Git Bash window on Windows, you may see an error message
saying you need to use `winpty`. In that case you must use the following
command.

    winpty docker-compose exec --user magento2 web bash

This example specified the 'web' service container (see `docker-compose.yml`
for the other service names).

In general this works well, but on Windows the 'exec' command will exit if you
press CTRL+Z. If you like using CTRL+Z in Linux, this is rather annoying, so
SSH access is recommended instead when logging into the web container. (SSH is
not enabled on the other containers.)

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

Note: If using Unison for file syncing, you may need to rerun
`composer install` on your installation to recreate some symbolic links.

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


# Appendix 3: File Syncing

The biggest issue with using Docker or other virtualization technologies is
most developers (rightly) prefer using an IDE or text editor running natively
(on the laptop). The challenge then is how to get the editor to be able to
access the Magento source code where that code is also available to the web
container.

Docker supports "volume mounting" which allows a Docker container to directly
access the laptop file system. This works very well on Linux, but has
performance issues on Mac and Windows when you have large numbers of files
(such as with Magento).

Where volume mounts are not suitable (specifically, the Magento source code
directory on Mac and Windows), DevBox syncs the local and container file
systems using a program called Unison. Whenever a file in the watched local
file system is changed, it is copied into the web container, and vice versa.
This allows IDEs to be natively used on a laptop (or desktop) - Unison copies
file changes as soon as they are written to disk into the web conatiner.

DevBox uses a similar approach to the "Docker Sync" project
(http://docker-sync.io/) for file sharing, but only supports Unison.

Insiders secret: Unison is written in a language called OCaml. OCaml 4.01 and
4.02 changed a serialization algorithm in a backwards incompatible way. So you
need to make sure you have Unison binaries on Windows, Mac, and Linux compiled
with the same version of OCaml. Brew + Debian:Stretch + the supplied Windows
binary currently all match. If you try experimenting with other binaries,
beware the pit of despair when things start going strange for no apparent
reason!

There are a number of implications from the above.

* Most developers prefer to use a IDE such as PHP Storm for development. PHP
  Storm has special support for "remote PHP interpeters" via ssh. This makes
  source code development and debugging using PHP Storm relatively painless
  even when PHP and the web server are running inside a Docker container.
  However, PHP Storm still needs access to the the source code for editing and
  debugging, which is why Unison is required.

* There are several directories (such as log directories) which you can choose
  to mount via Docker volumes for easy access directly from your laptop. These
  files are generally small in number and size for which Docker volume mounting
  works fine. By default the volume mounts are commented out in the
  `docker-compose.yml` file for improved performance.

* Some frontend developer tools like Gulp and Grunt rely on file watching
  "iNotify" file system events. Docker Volume mounting on Windows does not
  support iNotify events at this time.

