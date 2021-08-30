# total-compose-cli

![v0.1.0](https://img.shields.io/badge/version-0.1.0-orange)

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

1. checks that both `docker` and `docker-compose` are installed

	Note: These must be set up ahead of time.
	[docker-ce](https://docs.docker.com/engine/install/) 
	[docker-compose](https://docs.docker.com/compose/install/)

2. clones this repository to `~/.total-compose`
3. adds `~/.total-compose/total-compose` to `$PATH` in `~/.profile`

	Note: Consider checking for and including `.profile` in your `.bash_profile` if you don't already:

	```bash
	if [ -r ~/.profile ]; then . ~/.profile; fi
	```

4. adds `~/.total-compose/total-compose` to `$PATH` for the current shell session

## Usage

total-compose prefers to use config.yaml in `~/.total-compose`, but you may specify 
a specific configuration file using `-c, --config=` instead.
