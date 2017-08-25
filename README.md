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

The container developers interact with the most is the web container. The
other containers are relatively shrink wrap.

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
  However, PHP Storm does need access to the the source code.

* There are several directories (such as log directories) which you can choose
  to mount via Docker volumes for easy access directly from your laptop. These
  files are generally small in number and size for which Docker volume mounting
  works fine. By default the volume mounts are commented out in the
  `docker-compose.yml` file.

* Some frontend developer tools like Gulp and Grunt rely on file watching
  "iNotify" file system events. Volume mounting on Windows does not support
  iNotify events at this time.

Where volume mounts are not suitable (that is, the Magento source code on Mac
and Windows), DevBox syncs the local and container file systems using a program
called Unison. Whenver a file in the watched local file system is changed, it
is coped into the web container, and vice versa. This allows IDEs to be
natively used on a laptop (or desktop) - Unison copies file changes as soon as
they are made into the web conatiner.

**Enabling Volume Mounts**

To enable volume mounting for the Magento source code (e.g. for Linux laptops),
uncomment the relevant volume mount line for `/var/www` in the provided
`docker-compose.yml` file. For Unison (e.g. for Mac and Windows), ensure the
line is commented out.

**Enabling Unison**

For Windows, a BAT file is provided with the appropriate command line options
to run Unison. For Mac, a shell script is provided. The scripts will restart
Unison automatically if the web container is restarted for some reason.
The script also does an optimized first pass to reduce noise on the console
(it normally reports every synchronized file).

On Windows, the easiest way to launch Unison is to run the Unison BAT file
in its own window using the START command or by double clicking on the BAT
file from Windows file explorer.

    START m2devbox-unison-sync.bat

On Mac, it is recommended to run the script in a separate Terminal window.

    ./m2devbox-unison-sync.sh

# Getting Started

Now you understand what file syncing approach you are going to use, you are now
ready to get up and going with DevBox.

## Prerequisites

* Install a recent version of Docker from http://docker.com/. Docker is
  available for Windows, Mac, and Linux. Volume mounting (described below)
  is not recommended for older versions of Docker or when using Docker inside
  VirtualBox on Windows.
* As part of the Docker installation process, on Windows 10 you may need to
  turn on Hyper-V and then grant Docker access to the `C:` drive for Docker to
  mount volumes correctly. This is described in the Docker documentation.
  Please note that turning on Hyper-V disables VirtualBox. If you run Docker
  in VirtualBox, please be aware that VirtualBox will have its own IP address
  (unlike Docker running in Hyper-V that default is accessed using
  "localhost").
* On Windows, it can be useful to install "Git Bash"
  (https://git-for-windows.github.io/). As well as Git, it includes a terminal
  emulator that works well with Docker as well as a small collection of Linux
  commands.

## Setting Up a New Environment

### 1. Create a Local Project Directory

To start a new project, download a copy of the files in this project to a
new empty directory. Normally you create a directory per project. (Developers
at an system integrator or agency may work on multiple projects at once, one
directory per project.) This project holds starter files for your project.

GitHub provides a "download ZIP" option if you don't have git installed 
locally.

  * TODO: http://github.com/alankent/magento2devbox-skeleton
  * Click on the green button "Clone or Download" and select "Download ZIP".
  * Extract the ZIP file contents into an empty directory.

### 2. Review and Update the docker-compose.yml File

Review the `docker-compose.yml` file in a text editor for adjustments such as
preferred local port numbers. There are comments in the file describing
the settings you are most likely to change.

If you work on multiple projects, create a separate directory per project (e.g.
"proj1", "proj2", etc). DevBox is not designed to switch between projects. You
must ensure the container names are different per project to avoid conflicts.
For example, the default web container name is "m2web" (NOT "web") and the
default database container is "m2db". Change these to "proj1-m2web" and
"proj1-m2db" to match your project name. 

### 3. Launch the Containers

Launch the containers using:

    docker-compose up -d

To get a bash prompt inside the web container, use

    docker-compose exec web bash

You should see a shell prompt of `m2$`.

You can check what containers are running using

    docker ps

You can also see what containers exist but are currently not running using

    docker ps -a

### 4. Composer Configuration

This section is optional, but includes Composer performance optimizations worth
considering if you work on multiple projects.

The recommended way to create and update projects is via Composer, a PHP
package manager. Magento provides a Composer repository from which Magento
(and extensions purchased from Magento Marketplace) can be downloaded.

There is also a Magento ZIP download which is faster to download, but you will
need to use Composer at some stage to install patches or extensions, so it is
recommended to start with Composer from day 1.

Composer supports a download cache. Having this mounted to a local directory on
your laptop allows downloads to be shared betwen containers. Cached downloads
make subsequent upgrades and new installs much faster. If you do not mount a
shared volume for this directory, you cannot share the cache between containers
and the cache will be lost when the container is removed. There is nothing
wrong with this other than a potentially larger network bill for downloads and
slower startup time for subsequent new projects.

Be aware the Composer can be slow to run at times. Give it a minute or two even
if no output is occurring.

DevBox sets the `COMPOSER_HOME` environment variable to
`/home/magento2/.composer`.

The first time you run Composer, it may prompt you for a username and password.
Enter your 'public' and 'private' keys from http://marketplace.magento.com/,
"My Profile", "Access keys" when prompoted. Just be aware that an `auth.json`
file holding your keys will be saved into `~/.composer/`. You may want to share
the Composer downloaded files but have a different `auth.json` file per project
by moving the `auth.json` file into your project's home directory (but not
committing this file to git for security reasons).

To summarize, the easiest thing is to do nothing - not mount a shared composer
repository. For those wanting the improved performance, it is recommended to
uncomment the line in the `docker-compose.yml` file to volume mount the
`/home/magento2/.composer` directory. Manually create ~/.composer on your
laptop if it does not already exist.

### 5. Install Magento

Next you need to install your Magento project inside the web container under
the `/var/www/magento2` directory. (Apache is configured by default to use
`magento2` as the document root.) There are multiple options here.

**Existing Project**

If you have an existing project with all the source code already under
`shared/www`, you can skip this section. If you use volume mounting, the code
will automatically be visible; if you use Unison, it will copy files on your
laptop into the web container when Unison is started. Not additional
configuration is required.

Note: If you decide to change the settings in `docker-composer.yml` after
the containers have been created, you will need to remove the current
containers and recreate them. This falls under the 'existing project' use case.
MAKE SURE THE SOURCE CODE IS UP TO DATE UNDER THE `shared/www` DIRECTORY BEFORE
DELETING THE CONTAINERS TO MAKE SURE YOU DO NOT ACCIDENTALLY LOSE ANY OF YOUR
WORK.

**Creating a New Project**

The following commands create a new, default, project.

First log into the web container.

    docker-compose exec web bash

Then create a new project under `/var/www/magento2`. Update the project version number below as appropriate.

    mkdir /var/www/magento2
    cd /var/www/magento2
    composer create-project --repository=https://repo.magento.com/ magento/project-community-edition:2.1.8 .
    chmod +x bin/magento

**Getting Code from a GitHub Project**

Saving your code in a private git repository on a hosting provider such as
GitHub or BitBucket is strongly recommended. Project structures can change
between developers, but the following is a possible example.

Log into the web container:

    docker-compose exec web bash

Check out the project from inside the container into the `magento2` directory.

    cd /var/www
    git clone https://github.com/mycompany/myproject.git magento2
    cd /var/www/magento2
    composer install

**Magento Commerce (Cloud)**

TODO

**Internal Development**

This section is relevant to internal Magento developers, or external developers
wishing to submit a pull request. The following is NOT recommended for
production sites. (It may however be worth exploring by extension developers.)

Log into the web container:

    docker-compose exec web bash

Make a local clone of Magento Open Source (formerly Community Edition). Use
your own fork repository URL if appropriate.

    cd /var/www
    git clone https://github.com/magento/magento2.git
    cd /var/www/magento2
    composer install

Clone any other projects such as Magento Commerce (formerly Enterprise Edition)
or the B2B code base, if you have appropriate permissions.

    cd /var/www
    git clone https://github.com/magento/magento2ee.git
    cd /var/www/magento2
    composer require ...TODO...

### 6. Create the Database

The MySQL container by default does not have a database created for Magento
to use. The following creates the database `magento2`.

Log on to the bash prompt inside the web container

    docker-compose exec web bash

Tun the following commands to create a MyQL database to use.

    mysql -e 'CREATE DATABASE IF NOT EXIST magento2;'

After the database is created, you can uncomment the line setting the default
database in the MySQL `~/.my.cnf` file so that when you run `mysql` from the
command prompt it will log you in and select the `magento2` database by
default. (If this is set when the database does not exist, `mysql` will fail to
start.) This is not mandatory, but is convenient.

    mysql
    > SHOW TABLES;
    > exit;

Next, put the site into developer mode.

    cd /var/www/magento2
    magento deploy:mode:set developer

Set up all the Magento 2 tables with the following command (adjusting command
line paramter values as desired).

    cd /var/www/magento2
    magento setup:install --db-host=db --db-name=magento2 --db-user=root --db-password=magento2 --admin-firstname=Magento --admin-lastname=Administrator --admin-email=user@example.com --admin-user=admin --admin-password=admin123 --language=en_US --currency=USD --timezone=America/Chicago --use-rewrites=1 --backend-frontname=admin

It is recommended to NOT include the `--base_url` option during development as
Docker can allocate a port number at random (including when container is
restarted). It also causes problems using BrowserSync and similar tools for
frontend development. (Some versions of Magento however have a bug requiring
`--base_url` to be specified. If the URL to CSS files is incorrect, you may
have a broken version of Magento.)

If you are using RabbitMQ (AMPQ), the following command line arguments should
be added when the project is created.

    --amqp-virtualhost=/ --ampq-host=ampq --amqp-port=TODO --amqp-user=guest --amqp-password=guest

If you want to load the Luma sample data (optional), run the following
additional commands.

    cd /var/www/magento2
    magento sampledata:deploy
    magento setup:upgrade

### 7. Start Unison, if Needed

If you are using Unison for file syncing, you also need to start up a Unison
process (and keep it running). It is generally recommended to start this up
after you have installed Magento above.

On Windows, get a compatible version of the Unison binaries for Windows
from inside the container using the following (adjust "m2web" to your
web container name from the `docker-compose.yml` file - there is no
`docker-compose cp` command at this time so you cannot use "web", the service
name).

    docker cp m2web:/windows/unison.exe .
    docker cp m2web:/windows/unison-fsmonitor.exe .

Then run the supplied BAT file in a separate window using the START command or
by double clicking via Windows explorer. Close the window to kill Unison.

    START m2devbox-unison-sync.bat

Each time you log in, make sure you restart this process, but be careful to not
have multiple copies running. If you stop work on the project, you can close
this window and start it up again later.  It is not recommended to do
significant work on the project without Unison running to avoid merge conflicts
(rare).

Mac binaries and a shell script are also provided:

    docker cp m2web:/macos/unison .
    docker cp m2web:/macos/unison-fsmonitor .
    chmod +x unison unison-fsmonitor

It is recommended to run the sync shell script in a separat Terminal window.

    ./m2devbox-unison-sync.sh

### 8. Connect with a Web Browser

To access the web server, if you set the web port using the {localport}:80
syntax (e.g. 8080:80), access the page using the specified localport (e.g.
http://localhost:8080/). If you did not specify a local port, a random port
that is not currently in use will be allocated by Docker. You can use
`docker-compose` with the server name "web" to fetch the local port number
that is bound to the web server port.

    docker-compose port web 80

Be aware that in developer mode the slower PHP debug mode is on and missing
CSS and similar files are created on demand. This means the first time you
load a page you will see significantly longer load times.

### 9. Cron

TODO: By default, to save batteries/energy, cron is disabled. Running cron in container can result in faster laptop battery drainging. To enable cron, you can follow the instructions in the documentation http://devdocs.magento.com/guides/v2.1/install-gde/docker/docker-commands.html.

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
