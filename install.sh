#!/bin/bash
## Total-Compose requires some programs to be installed to function correctly.
REQUIRED=("docker docker-compose")

## Is Program Installed? If not, add it to missing.
## Uses $required_program variable as a "parameter"
check_program_exists() {
	echo -n "Verifying $required_program exists.."
	if ! command -v $required_program &> /dev/null
	then
		echo "false"
		missing+=($required_program)
	else
		echo "true"
	fi
}

## Check for pre-requisites
missing=()
for required_program in $REQUIRED
do
	check_program_exists
done

if [ ${#missing[@]} -eq 0 ]
then
	echo "All requirements met."
else
	echo "Missing at least one required program."
	echo "Please install the following before trying again:"
	echo "    $missing"
	exit 1
fi

## Do the installation..
echo "Adding total-compose to PATH in ~/.profile"
echo 'PATH=$PATH:~/.total-compose-cli/total-compose' >> ~/.profile
echo "Updating PATH for this session"
export PATH=$PATH:/.total-compose-cli/total-compose
