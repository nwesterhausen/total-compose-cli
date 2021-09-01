## Useful docker container backup scripts from Luis Bianchin on stackoverflow.
##	https://stackoverflow.com/a/34776997
##
## At the time he wrote that, busybox might not have been able to do the compression.
## But as of August 2021, tar in busybox can do compression, so I have edited the
## two backup and restore functions.
##
## I also have edited the functions to name the backups with the container name.
## It seemed a simple thing to do to avoid clobbering data accidentally.
##
## To use:
##		 docker-volume-backup container_name mount_point1[-n]
##       docker-volume-restore container_name mount_point1[-n]
##
## Since the busybox image plops you in "/", all mount points do not require the
## forward-slash.
##
## Feel free to source this file from your ~/.profile

# backup files from a docker volume into /tmp/CONTAINER_NAME.tar.gz
function docker-volume-backup() {
  docker run --rm -v /tmp:/backup --volumes-from "$1" busybox tar -czvf "/backup/$1.tar.gz" "${@:2}"
}
# restore files from /tmp/CONTAINER_NAME.tar.gz into a docker volume
function docker-volume-restore() {
  docker run --rm -v /tmp:/backup --volumes-from "$1" busybox tar -xzvf "/backup/$1.tar.gz" "${@:2}"
  echo "Double checking files..."
  docker run --rm -v /tmp:/backup --volumes-from "$1" busybox ls -lh "${@:2}"
}
# list all files in docker volumes of a container
function docker-volume-list() {
  docker run --rm -v /tmp:/backup --volumes-from "$1" busybox ls -lh "${@:2}"
}
