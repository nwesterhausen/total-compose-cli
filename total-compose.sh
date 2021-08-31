#!/bin/bash
## From https://github.com/nwesterhause/total-compose-cli
## MIT Licenced
##
## To change the yq command used in this script, edit set_config()
##
## Exit Codes:
##  1: [NOT USED] Previously, in 0.1.0-pre was used for no cli parameters
##  2: "Configuration file invalid: either doesn't exist or isn't file-like"
##  3: "Compose file doesn't appear to exist"
##  4: "Empty configuration path." or "No config file specified"
##  5: "Unknown service, this shouldn't have happened."

## Set config
set_config(){
	if [[ ! -f "$CONFDIR/$CONFFILE" ]]; then
		error_msg "Configuration file invalid: either doesn't exist or isn't file-like"
    usage
		exit 2
	fi
	echo "CONFIG: Using $CONFFILE in $CONFDIR/."

	## YQ invocation variable (change this if you don't like using docker run --rm for yq)
	local YQ="docker run --rm -v $CONFDIR:/workdir mikefarah/yq"
	#YQ="yq"

	NAMELIST=(`$YQ e '... comments="" | .services[].name' $CONFFILE | tr "\n" " "`)
	COMPOSELIST=(`$YQ e '... comments="" | .services[].location' $CONFFILE | tr "\n" " "`)
	readarray DESCLIST < <($YQ e '... comments="" | .services[].description' $CONFFILE)

  CONFYESALL=`$YQ e '... comments="" | .assume-yes' $CONFFILE`

  if [[ $configcheck = 1 ]]; then
    echo "YQ parsed config file:"
    if [[ $nocolor -eq 1 ]]; then
      $YQ e '... comments="" | .' $CONFFILE
    else
      $YQ --colors e '... comments="" | .' $CONFFILE
    fi
  fi
}

## Usage display
usage(){
cat <<EOF
total-compose v0.2.2-pre
Usage: total-compose [options] [servicegroup] [action]

Valid option flags:
  -c, --config=   Path of config file if not using ~/.total-compose/config.yaml
  --no-color      Disable color output

To see valid actions, run 'docker-compose help'. 

servicegroup must not match a docker-compose subcommand and must match one of the
defined names in the config file. If it doesn't match a name in the config file,
it becomes part of the 'action' parameter.

total-compose simplifies calling docker-compose on the compose files specified in
the config file. Any command you can perform with docker-compose can be performed 
with this tool. This tool calls 'docker-compose -f FILE_LOCATION [action]' depending 
on which service name you provided. If no action is provided, this will check
current status for the services in the docker-compose file. (docker-compose ps)

EOF
  echo "Config used: $CONFFILE in $CONFDIR"
  echo
  echo "The following service stacks were read from the configuration file:"
  for i in "${!NAMELIST[@]}"; do
		display_config "${NAMELIST[$i]}" "${COMPOSELIST[$i]}" "${DESCLIST[$i]}"
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
      error_msg "Empty configuration path."
      exit 4
    fi
}

## Error (red) text
error_msg() {
  if [[ $nocolor = 1 ]]; then
    echo $@
  else
    local RED='\033[0;31m'
    local NC='\033[0m'
    printf "${RED}%s${NC}\n" "$1"
  fi
}

## Attention (yellow) text
attention_msg() {
  if [[ $nocolor = 1 ]]; then
    echo $@
  else
    local YLW='\033[0;33m'
    local NC='\033[0m'
    if [[ $1 = "-n" ]]; then      
      printf "${YLW}%s${NC}" "$2"
    else
      printf "${YLW}%s${NC}\n" "$1"
    fi
  fi
}

## Success (lime) text
success_msg() {
  if [[ $nocolor = 1 ]]; then
    echo $@
  else
    local LIME='\033[32;1m'
    local NC='\033[0m'
    printf "${LIME}%s${NC}\n" "$1"
  fi
}

## Colorize service output
display_config() {
  if [[ $nocolor = 1 ]]; then
    echo $@
  else
    local CYAN='\033[0;36m'
    local GREEN='\033[0;32m'
    local NC='\033[0m'
    if [[ $# -eq 2 ]]; then
      printf "${CYAN}%s${NC}:\t${GREEN}%s${NC}\n" "$1" "$2"
    else
      printf "${CYAN}%s${NC}:\t${GREEN}%s${NC}\n\t%s\n" "$1" "$2" "$3"
    fi
  fi
}

## SET DEFAULT
CONFDIR="$HOME/.total-compose"
CONFFILE="config.yaml"
nocolor=0

## Parse flags
while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      set_config
      usage
      exit 0
      ;;
    --no-color|--no-colors)
      nocolor=1
      shift
      ;;
    -c)
      shift
      if [[ $# -gt 0 ]]; then
        save_configpath $1
      else
        error_msg "No config file specified"
        exit 4
      fi
      shift
      ;;
    --config*)
      save_configpath `echo $1 | sed -e 's/^[^=]*=//g'`
      shift
      ;;
    --check|-t|--test)
      configcheck=1
      shift
      ;;
    *)
      break
      ;;
  esac
done

if [[ $configcheck=1 ]]; then
      attention_msg "Config will be printed."
fi

set_config

## Check for having no more cli arguments
if [[ $configcheck = 1 ]]; then
  echo ""
  echo "Total-compose parsed configuration:"
  display_config "assume-yes" $CONFYESALL
  for i in "${!NAMELIST[@]}"; do
      display_config "${NAMELIST[$i]}" "${COMPOSELIST[$i]/#\~/$HOME}" "`echo "${DESCLIST[$i]}" | tr -d "\n"`"
  done
  exit 0
elif [[ $# -lt 1 ]]; then
  attention_msg "No command specified, by default 'ps' will be passed to docker-compose"
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
    attention_msg -n "Confirm that you want to apply the action to all stacks (y/n)? "
    read answer
    if [ "$answer" != "${answer#[Yy]}" ] ;then
        success_msg "Will execute same docker-compose command for all service stacks."
        DOALL=1
    else
        attention_msg "Stopping the script. Check $CONFFILE or specify a service:"
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
        display_config "$service" "$composefile"
        if [[ ! -f $composefile ]]; then
          error_msg "Compose file doesn't appear to exist"
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
  error_msg "Unknown service, this shouldn't have happened."
  exit 5
fi
for i in "${!NAMELIST[@]}"; do
  if [[ "${NAMELIST[$i]}" = "${service}" ]]; then
    composefile=${COMPOSELIST[$i]/#\~/$HOME}
    display_config "$service" "$composefile"
    if [[ ! -f $composefile ]]; then
      error_msg "Compose file doesn't appear to exist"
      exit 3
    fi
    if [[ $# -lt 1 ]]; then
        docker-compose -f "$composefile" ps
    else
        docker-compose -f "$composefile" $@
    fi
    
   fi
done