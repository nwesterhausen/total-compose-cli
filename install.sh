#!/bin/bash
## Total-Compose requires some programs to be installed to function correctly.
REQUIRED=("docker docker-compose git")

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
if [[ -d "${HOME}/.total-compose" ]]
then
	echo "Repo exists."
else
	echo "Cloning repo into ~/.total-compose"
	git clone https://github.com/nwesterhausen/total-compose-cli.git ~/.total-compose
fi

## Link to bin dir in path
if [[ -d "${HOME}/.local/bin" ]]
then
	echo "Installing to ~/.local/bin"
	ln -s "${HOME}/.total-compose/total-compose.sh" "${HOME}/.local/bin/total-compose"
elif [[ -d "${HOME}/bin" ]]
then
	echo "Installing to ~/bin"
	ln -s "${HOME}/.total-compose/total-compose.sh" "${HOME}/.local/bin/total-compose"
else
	echo "Did not find a local friendly bin folder. (Checked ~/.local/bin and ~/bin)"
	echo "Please manually add ~/.total-compose/total-compose.sh into your PATH"
fi
