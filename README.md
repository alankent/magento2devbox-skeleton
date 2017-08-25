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
systems using a program called Unison. Whenver a file in the watched local file
system is changed, it is copied into the web container, and vice versa. This
allows IDEs to be natively used on a laptop (or desktop) - Unison copies file
changes as soon as they are written to disk into the web conatiner.

# Installation

Now you understand what file syncing approach you are going to use, you are now
ready to get up and going with DevBox.

## Prerequisites

* Install a recent version of Docker from http://docker.com/. Docker is
  available for Windows, Mac, and Linux. 
* As part of the Docker installation process, on Windows 10 you may need to
  turn on Hyper-V and then grant Docker access to the `C:` drive for Docker to
  mount volumes correctly. This is described in the Docker documentation.
* On Windows, it can be useful to install "Git Bash"
  (https://git-for-windows.github.io/). As well as Git, it includes a terminal
  emulator as well as a useful collection of Linux commands.

## Setting Up a New Environment

### 1. Create a Local Project Directory

Create a new directory per project. Download a copy of the files in this
GitHub repository to the project directory.

  * Go to http://github.com/alankent/magento2devbox-skeleton
  * In the "Branch" drop down, select the tag closest to the project's version
    of Magento. This is to get the correct version of PHP, MySQL, etc.
    If in doubt, pick "master" (the default).
  * Click on the green button "Clone or Download" and select "Download ZIP".
  * Extract the ZIP file contents into the project directory.

### 2. Review and Update the docker-compose.yml File

Review the `docker-compose.yml` file in a text editor, making necessary
adjustments as described by comments in the file. This includes:

* You MUST ensure the container names are different per project to avoid
  conflicts. For example, the default web service container name is
  "proj1-m2web" and the default db service container name is "proj1-m2db".
  Change all occurrences of "proj1" to your project name.

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
  `docker-compose.yml` file. This allows downloads to be shared betwen
  containers (e.g. on different projects). If you do not mount a directory, the
  cache will discarded when the container is removed.

### 3. Launch the Containers

Launch the containers by changing to the project directory and then running:

    docker-compose up -d

You can check what containers exist using

    docker ps -a

To get a bash prompt inside the web container, use

    docker-compose exec web bash

You should see a shell prompt of `m2$`. If you are using the Git Bash window,
you may see an error message saying you need to use `winpty`. In that case
you must use the following command to create a bash prompt.

    winpty docker-compose exec web bash

### 4. Install Magento

Next you need to install your Magento project inside the web container under
the `/var/www/magento2` directory. (Apache is configured by default to use
`magento2` as the document root.) There are multiple options here.

Note: The first time you run Composer in the following steps, it may prompt you
for a username and password. Enter your 'public' and 'private' keys from
http://marketplace.magento.com/, "My Profile", "Access keys" when prompoted. Be
aware that an `auth.json` file holding your keys will be saved into
`~/.composer/`. You may want to share the Composer downloaded files but have a
different `auth.json` file per project by moving the `auth.json` file into your
project's home directory (but not committing this file to git for security
reasons).

**Existing Project**

If you have an existing project with all the source code already under
`shared/www`, no additional configuration is needed. If you use volume
mounting, the code will automatically be visible; if you use Unison, it will
copy files on your laptop into the web container when Unison is started.

**Creating a New Project with Composer**

Log into the web container.

    docker-compose exec web bash

Create a new project under `/var/www/magento2`. (Update the project version
number as appropriate.)

    cd /var/www/magento2
    xdebug-off
    composer create-project --repository=https://repo.magento.com/ magento/project-community-edition:2.1.8 .
    chmod +x bin/magento

**Getting Code from a GitHub Project**

It is strongly recommended to saving your project code in a private git
repository on a hosting provider such as GitHub or BitBucket.

Log into the web container:

    docker-compose exec web bash

Check out the project from inside the container into the `magento2` directory.

    cd /var/www
    git clone https://github.com/mycompany/myproject.git magento2
    cd magento2
    xdebug-off
    composer install

**Magento Commerce (Cloud)**

TODO

**Internal Development**

This section is ONLY relevant to internal Magento developers, or external
developers wishing to submit a pull request. The following is NOT recommended
for production sites. (It may however be worth exploring by extension
developers.)

Log into the web container:

    docker-compose exec web bash

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

### 6. Create the Database

The MySQL container by default does not have a database created for Magento
to use. The following creates the database `magento2`.

Log on to the bash prompt inside the web container

    docker-compose exec web bash

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
line paramter values as desired).

    magento setup:install --db-host=db --db-name=magento2 --db-user=root --db-password=root --admin-firstname=Magento --admin-lastname=Administrator --admin-email=user@example.com --admin-user=admin --admin-password=admin123 --language=en_US --currency=USD --timezone=America/Chicago --use-rewrites=1 --backend-frontname=admin

It is recommended to NOT include the `--base_url` option during development as
Docker can allocate a port number at random (including when container is
restarted). It also causes problems using BrowserSync and similar tools for
frontend development. Some versions of Magento however have a bug requiring
`--base_url` to be specified. If the URL to CSS files is incorrect, you may
have a broken version of Magento.

If you are using RabbitMQ (AMPQ), the following command line arguments should
be added when the project is created.

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

### 7. Put Site into Developer Mode

Put the site into developer mode. Turning on xdebug is useful for debuging
purposes, but makes all PHP scripts slower to execute.

    magento deploy:mode:set developer
    xdebug-on

### 7. Start Unison, if Needed

If you are using Unison for file syncing, you also need to start up a Unison
process (and keep it running). It is generally recommended to start this up
after you have installed Magento above.

On Windows, get a compatible version of the Unison binaries for Windows
from inside the container using the following (adjust "proj1-m2web" to match
your web service container name from the `docker-compose.yml` file).

    docker cp proj1-m2web:/windows/unison.exe .
    docker cp proj1-m2web:/windows/unison-fsmonitor.exe .

Then run the supplied BAT file to launch Unison in a separate window using the
START command or by double clicking the BAT file via Windows explorer. Close
the window to kill Unison.

    START m2devbox-unison-sync.bat

Each time you log in, make sure you restart this process, but be careful to not
have multiple copies running in parallel. It is not recommended to do
significant work on the project without Unison running to avoid merge conflicts
(rare).

Mac binaries and a shell script are also provided:

    docker cp proj1-m2web:/macos/unison .
    docker cp proj1-m2web:/macos/unison-fsmonitor .
    chmod +x unison unison-fsmonitor

It is recommended to run the sync shell script in a separat Terminal window.

    ./m2devbox-unison-sync.sh

### 8. Connect with a Web Browser

Run the following command to determine the web server port number.

    docker-compose port web 80

Be aware that in developer mode the slower PHP debug mode is on and missing
CSS and similar files are created on demand. This means the first time you
load a page you will see significantly longer load times.

### 9. Cron

Cron is disabled by default. Running cron may result in faster draining of
laptop batteries. To manually trigger background index updates, run `magento
cron:run` twice in a row (sometimes the first cron schedules jobs for the
second cron to run)

    magento cron:run
    magento cron:run

To enable cron permanently run the following command.

    cat <<EOF | crontab -
    * * * * * /usr/local/bin/php /var/www/magento2/bin/magento cron:run | grep -v "Ran jobs by schedule" >> /var/www/magento2/var/log/magento.cron.log
    * * * * * /usr/local/bin/php /var/www/magento2/update/cron.php >> /var/www/magento2/var/log/update.cron.log
    * * * * * /usr/local/bin/php /var/www/magento2/bin/magento setup:cron:run >> /var/www/magento2/var/log/setup.cron.log
    EOF

### 10. Configure PHP Storm (if appropriate)

TODO: Script? SSH and Remote Interpreters?

### 11. Varnish Configuration
TODO
### 12. Redis Configuration
TODO
### 13. Grunt Configuration
TODO
### 14. Gulp Configuration
TODO

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

When you no longer need the container, you can kill and remove it. THIS WILL
WIPE ALL FILES INSIDE THE CONTAINER, LOSING ANY CHANGES FOREVER. It will not
remove the locally synchronized files under the `shared` directory.

    docker-compose kill
    docker-compose rm

If you decide to change the settings in `docker-composer.yml` after the
containers have been created, you will need to remove the current containers
and recreate them (including the database contents). MAKE SURE THE SOURCE CODE
IS UP TO DATE UNDER THE `shared/www` DIRECTORY BEFORE DELETING THE CONTAINERS
TO MAKE SURE YOU DO NOT ACCIDENTALLY LOSE ANY OF YOUR WORK.

    docker-compose kill
    docker-compose rm
    # Make changes to docker-compose.yml
    docker-compose up -d

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

# Contributions

Please use GitHub (TODO: INSERT URL) for issue tracking or to make
contributions.
