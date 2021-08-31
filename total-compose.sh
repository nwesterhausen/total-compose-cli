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
    usage
		exit 3
	fi

	## YQ invocation variable (change this if you don't like using docker run --rm for yq)
	local YQ="docker run --rm -v $CONFDIR:/workdir mikefarah/yq"
	#YQ="yq"

	readarray NAMELIST < <($YQ e '... comments="" | .services[].name' $CONFFILE | tr -d '[:space:]')
	readarray COMPOSELIST < <($YQ e '... comments="" | .services[].location' $CONFFILE | tr -d '[:space:]')
	readarray DESCLIST < <($YQ e '... comments="" | .services[].description' $CONFFILE)

  CONFYESALL=`$YQ e '... comments="" | .assume-yes' $CONFFILE`

  if [[ $configcheck = 1 ]]; then
    echo "Parsed config file:"
    $YQ e '... comments="" | .' $CONFFILE
  fi
}

## Usage display
usage(){
  myname=$(basename "$0")
  echo "total-compose v0.2.1-pre"
  echo "Usage: $myname [options] servicegroup [action]"
  echo ""
  echo "Valid option flags:"
  echo "    -c, --config=		Path of config file if not using ~/.total-compose/config.yaml"
  echo ""
  echo "To see valid actions, run 'docker-compose help'"
  echo ""
  echo "$myname simplifies calling docker-compose on the compose files in this repository."
  echo "Any command you can perform with docker-compose can be performed with this tool."
  echo "This tool calls 'docker-compose -f FILE_LOCATION [action]' depending on"
  echo "which configured service you provided. If no action is provided, this will check"
  echo "current status for the services in the docker-compose file. (docker-compose ps)"
  echo ""
  echo "Config used: $CONFFILE in $CONFDIR"
  echo ""
  echo "The following service stacks were read from the configuration file:"
  for i in "${!NAMELIST[@]}"; do
		printf "%s\t%s\n\t%s" "${NAMELIST[$i]}" "${COMPOSELIST[$i]}" "${DESCLIST[$i]}"
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

## Parse flags
while [[ $# -gt 0 ]]; do
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
    --check|-t|--test)
      echo "Will check config"
      configcheck=1
      shift
      ;;
    *)
      break
      ;;
  esac
done

set_config

## Check for having no more cli arguments
if [[ $configcheck = 1 ]]; then
  echo ""
  echo "Printing parsed configuration:"
  echo "assume-yes: $CONFYESALL"
  for i in "${!NAMELIST[@]}"; do
      printf "%s:\t%s\n\t%s\n" "${NAMELIST[$i]}" "${COMPOSELIST[$i]/#\~/$HOME}" "${DESCLIST[$i]}"
  done
  exit 0
elif [[ $# -lt 1 ]]; then
  echo "No command specified, by default 'ps' will be passed to docker-compose"
  command="ps"
fi

## Next cli argument should be one of the names we gathered. If it isn't
## then we will assume you want to do something to everything.
if [[ ! " ${NAMELIST[@]} " =~ " ${1} " ]]; then
  echo "$1 is not defined in config, passing it through to docker-compose"
  ## Check unless the config entry "assume-all" is true
  if [[ $CONFYESALL = "true" ]]; then
    echo "assume-all is set in config, will apply action to all stacks."    
    DOALL=1
  else
    echo -n "Confirm that you want to apply the action to all stacks (y/n)? "
    read answer
    if [ "$answer" != "${answer#[Yy]}" ] ;then
        echo "Will execute same docker-compose command for all service stacks."
        DOALL=1
    else
        echo "Stopping the script. Check $CONFFILE or specify a service:"
        echo "    $NAMELIST"
        exit 0
    fi
  fi
fi

if [[ $DOALL = 1 ]]; then
    if [[ -z ${command+x} ]]; then
      command=$@
    fi    
    echo "Performing this command on all services:"
    echo "    docker-compose $command"
    for i in "${!NAMELIST[@]}"
    do
        service=${NAMELIST[$i]}
        composefile=${COMPOSELIST[$i]/#\~/$HOME}
        echo "$service: $composefile"
        if [[ ! -f $composefile ]]; then
          echo "Compose file doesn't appear to exist"
          exit 3
        fi
        if [[ $# -lt 1 ]]; then
            docker-compose -f "$composefile" ps
        else
            docker-compose -f "$composefile" $@
        fi
    done
    exit 0
fi

service=$1
shift

if [[ ! " ${NAMELIST[@]} " =~ " ${service} " ]]; then
  echo "Unknown service, this shouldn't have happened."
  exit 5
fi
for i in "${!NAMELIST[@]}"; do
  if [[ "${NAMELIST[$i]}" = "${service}" ]]; then
    composefile=${COMPOSELIST[$i]/#\~/$HOME}
    echo "$service: $composefile"
    if [[ ! -f $composefile ]]; then
      echo "Compose file doesn't appear to exist"
      exit 3
    fi
    if [[ $# -lt 1 ]]; then
        docker-compose -f "$composefile" ps
    else
        docker-compose -f "$composefile" $@
    fi
    
   fi
done