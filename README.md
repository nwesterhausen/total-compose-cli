# total-compose-cli

## Installation

Run the `install.sh` script. Here's what it does:

1. checks that both `docker` and `docker-compose` are installed

	Note: These must be set up ahead of time. [Docker-ce]() | [Docker-compose]()

2. clones this repository to `~/.total-compose`
3. adds `~/.total-compose/total-compose` to `$PATH` in `~/.profile`

	Note: Consider checking for and including `.profile` in your `.bash_profile` if you don't already:

	```bash
	if [ -r ~/.profile ]; then . ~/.profile; fi
	```

4. adds `~/.total-compose/total-compose` to `$PATH` for the current shell session
