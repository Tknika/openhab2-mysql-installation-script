## Introduction

Bash script to automatically install and configure the persistence part of openHAB2 using MySQL.

## Features

The script installs the following packages:

- MySQL server
- MySQL persistence addon (openHAB2)

All items states are persisted on every change and restored on startup.

## Installation

The script has been succesfully tested on a Raspberry Pi, but it should work on any Debian based (Ubuntu) distribution.

wget https://raw.githubusercontent.com/Tknika/openhab2-mysql-installation-script/master/install.sh

chmod +x install.sh

sudo ./install.sh

When you run it, you can choose the database root password and the openhab user password. If you leave them blank, default values
will be used: "mysql" for the root password and "openhab" for the openhab user password. 

Enjoy!
