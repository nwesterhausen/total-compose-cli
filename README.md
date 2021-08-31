# total-compose-cli

![v0.2.1-pre](https://img.shields.io/badge/version-0.2.1--pre-orange)

total-compose is a docker-compose helper which lets you specify docker-compose.yml files using
keywords (names) and do so from the comfort of $HOME regardless of where the compose file
is at. 

total-compose started as a hardcoded shell script but this is the attempt to make it generic and
usable by other people (and by myself on other machines). You can run the install script or
manually install. See the [installation](#installation) section for details on what happens during
the installation.

To read its config, total-compose will use [`yq`](http://mikefarah.github.io/yq/)
to parse and understand what commands you give it. Because docker will already be present, 
by default, `yq` is invoked using `docker run --rm -v "${$CONFDIR}":/workdir mikefarah/yq`.
`$CONFDIR` is the directory container the config file, so by default is `~/.total-compose`.
The way total-compose calls `yq` can be modified by editing the `$YQ` variable in the 
`total-compose` file.

## Installation

Run the `install.sh` script. Here's what it does:

1. checks that `docker`, `docker-compose`, and `git` are installed

	Note: These must be set up ahead of time.
	[docker-ce](https://docs.docker.com/engine/install/) 
	[docker-compose](https://docs.docker.com/compose/install/)

2. clones this repository to `~/.total-compose`
3. links the `total-compose` script to a discovered bin folder in either `~/bin` or `~/.local/bin`

## Usage

```
nwest@ubuntu-server:~/.total-compose$ total-compose -h
CONFIG: Using config.yaml in /home/nwest/.total-compose.
total-compose v0.2.0-pre
Usage: /home/nwest/.local/bin/total-compose [options] servicegroup [action]

Valid option flags:
    -c, --config=               Path of config file if not using ~/.total-compose/config.yaml

To see valid actions, run 'docker-compose help'

/home/nwest/.local/bin/total-compose simplifies calling docker-compose on the compose files in this repository.
Any command you can perform with docker-compose can be performed with this tool.
This tool calls 'docker-compose -f FILE_LOCATION [action]' depending on
which configured service you provided. If no action is provided, this will check
current status for the services in the docker-compose file. (docker-compose ps)

Config used: config.yaml in /home/nwest/.total-compose

The following service stacks were read from the configuration file:
who     ~/whoami/docker-compose.yml
        Simple whoami service which sits and answers with whoami.
```

### Example
```yaml
# ~/.total-compose/config.yaml
services:
  - name: who
    location: ~/whoami/docker-compose.yml
    description: Simple whoami service which sits and answers with whoami.
assume-yes: false
```

```
nwest@ubuntu-server:~$ total-compose who config
CONFIG: Using config.yaml in /home/nwest/.total-compose.
who: /home/nwest/whoami/docker-compose.yml
services:
  whoami:
    image: traefik/whoami
version: '3.9'

nwest@ubuntu-server:~$ total-compose
CONFIG: Using config.yaml in /home/nwest/.total-compose.
No command specified, by default 'ps' will be passed to docker-compose
 is not defined in config, passing it through to docker-compose
Confirm that you want to apply the action to all stacks (y/n)? y
Will execute same docker-compose command for all service stacks.
Performing this command on all services:
    docker-compose ps
who: /home/nwest/whoami/docker-compose.yml
     Name         Command   State   Ports
------------------------------------------
whoami_whoami_1   /whoami   Up      80/tcp

nwest@ubuntu-server:~$ total-compose who down
CONFIG: Using config.yaml in /home/nwest/.total-compose.
who: /home/nwest/whoami/docker-compose.yml
Stopping whoami_whoami_1 ... done
Removing whoami_whoami_1 ... done
Removing network whoami_default
```