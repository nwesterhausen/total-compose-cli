#!/bin/bash
## From https://github.com/nwesterhause/total-compose-cli
## MIT Licenced
##
## To change the yq command used in this script, edit set_config()

## Set config
set_config(){
	echo "CONFIG: Using $CONFFILE in $CONFDIR."
	if [[ ! -f "$CONFDIR/$CONFFILE" ]]; then
		echo "Configuration file invalid: either doesn't exist or isn't file-like"
		exit 3
	fi

	## YQ invocation variable (change this if you don't like using docker run --rm for yq)
	local YQ="docker run --rm -v $CONFDIR:/workdir mikefarah/yq"
	#YQ="yq"

	readarray NAMELIST < <($YQ e '... comments="" | .services[].name' $CONFFILE)
	readarray COMPOSELIST < <($YQ e '... comments="" | .services[].location' $CONFFILE)
	readarray DESCLIST < <($YQ e '... comments="" | .services[].description' $CONFFILE)
}

## Usage display
usage(){
    echo "total-compose v0.1.0-pre"
	echo "Usage: $0 [options] servicegroup [action]"
	echo ""
	echo "Valid option flags:"
	echo "    -c, --config=		Path of config file if not using ~/.total-compose/config.yaml"
    echo ""
	echo "To see valid actions, run 'docker-compose help'"
	echo ""
    echo "$0 simplifies calling docker-compose on the compose files in this repository."
    echo "Any command you can perform with docker-compose can be performed with this tool."
    echo "This tool calls 'docker-compose -f FILE_LOCATION [action]' depending on"
    echo "which configured service you provided. If no action is provided, this will check"
    echo "current status for the services in the docker-compose file. (docker-compose ps)"
    echo ""
	echo "Config used: $CONFFILE in $CONFDIR"
	echo ""
    echo "The following service stacks were read from the configuration file:"
    for i in "${!NAMELIST[@]}"; do
		printf "%s\t%s\t%s\n" "${NAMELIST[$i]}" "${DESCLIST[$i]}" "${COMPOSELIST[$i]}"
	done
}

## Split configpath into directory and file
save_configpath() {
    echo "parsing $@ ($1)"
    if [[ ! -z ${1+x} ]]; then
      CONFDIR=$(dirname "$1")
      CONFDIR="${CONFDIR/#\~/$HOME}"
      CONFDIR="${CONFDIR/#\./`pwd`}"
      CONFFILE=$(basename "$1")
    else
      echo "Empty configuration path."
      exit 4
    fi
}

## SET DEFAULT
CONFDIR="$HOME/.total-compose"
CONFFILE="config.yaml"

## Check for having no cli arguments
if [[ $# -lt 1 ]]; then
	set_config
	usage
	exit 1
fi

## Parse flags
while [[ $# -gt 0 ]]; do
  echo "Testing flag $1"
  case "$1" in
    -h|--help)
	  set_config
      usage
      exit 0
      ;;
    -c)
      shift
      if [[ $# -gt 0 ]]; then
        save_configpath $1
      else
        echo "no config file specified"
        exit 1
      fi
      shift
      ;;
    --config*)
      save_configpath `echo $1 | sed -e 's/^[^=]*=//g'`
      shift
      ;;
    *)
      break
      ;;
  esac
done

set_config

## Check for having no more cli arguments
if [[ $# -lt 1 ]]; then
  echo ""
  echo "Printing parsed configuration:"
  for i in "${!NAMELIST[@]}"; do
      printf "%s\t%s\t%s\n" "${NAMELIST[$i]}" "${DESCLIST[$i]}" "${COMPOSELIST[$i]}"
  done
  exit 0
fi

