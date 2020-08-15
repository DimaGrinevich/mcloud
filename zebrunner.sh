#!/bin/bash

  setup() {
    # PREREQUISITES: valid values inside ZBR_PROTOCOL, ZBR_HOSTNAME and ZBR_PORT env vars!
    local url="$ZBR_PROTOCOL://$ZBR_HOSTNAME:$ZBR_PORT"

    if [[ ! -f .env.original ]]; then
      #make a backup of the original file
      cp .env .env.original
    fi
    sed -i "s#localhost#${ZBR_HOSTNAME}#g" .env

    if [[ ! -f variables.env.original ]]; then
      #make a backup of the original file
      cp variables.env variables.env.original
    fi
    sed -i "s#http://localhost:8082#${url}#g" variables.env
    sed -i "s#localhost#${ZBR_HOSTNAME}#g" variables.env
  }

  start() {
    # create infra network only if not exist
    docker network inspect infra >/dev/null 2>&1 || docker network create infra

    if [[ ! -f .disabled ]]; then
      docker-compose --env-file .env -f docker-compose.yml up -d
    fi
  }

  stop() {
    if [[ ! -f .disabled ]]; then
      docker-compose --env-file .env -f docker-compose.yml stop
    fi
  }

  down() {
    if [[ ! -f .disabled ]]; then
      docker-compose --env-file .env -f docker-compose.yml down
    fi
  }

  shutdown() {
    if [[ ! -f .disabled ]]; then
      docker-compose --env-file .env -f docker-compose.yml down -v
    fi

    if [[ -f .env.original ]]; then
      mv .env.original .env
    fi

    if [[ -f variables.env.original ]]; then
      mv variables.env.original variables.env
    fi

    echo "TODO: think about backup generation during shutdown."
  }

  backup() {
    echo "TODO: implement logic"
  }

  restore() {
    echo "TODO: implement logic"
  }

  echo_help() {
    echo "
      Usage: ./zebrunner.sh [option]
      Flags:
          --help | -h    Print help
      Arguments:
      	  start          Start container
      	  stop           Stop and keep container
      	  restart        Restart container
      	  down           Stop and remove container
      	  shutdown       Stop and remove container, clear volumes
      	  backup         Backup container
      	  restore        Restore container
      For more help join telegram channel https://t.me/qps_infra"
      exit 0
  }


  # That's a full copy of set_global_settings method from qps-infra/zebrunner.sh. Make sure to sync code in case of any change in all places
  set_global_settings() {
    # Setup global settings: protocol, hostname and port. 

    local is_confirmed=0
    ZBR_PROTOCOL=http
    ZBR_HOSTNAME=$HOSTNAME
    ZBR_PORT=80

    while [[ $is_confirmed -eq 0 ]]; do
      read -p "PROTOCOL [$ZBR_PROTOCOL]: " local_protocol
      if [[ ! -z $local_protocol ]]; then
        ZBR_PROTOCOL=$local_protocol
      fi

      read -p "FQDN HOSTNAME [$ZBR_HOSTNAME]: " local_hostname
      if [[ ! -z $local_hostname ]]; then
        ZBR_HOSTNAME=$local_hostname
      fi

      read -p "PORT [$ZBR_PORT]: " local_port
      if [[ ! -z $local_port ]]; then
        ZBR_PORT=$local_port
      fi

      confirm "URL: $ZBR_PROTOCOL://$ZBR_HOSTNAME:$ZBR_PORT" "Continue?"
      is_confirmed=$?
    done

    export ZBR_PROTOCOL=$ZBR_PROTOCOL
    export ZBR_HOSTNAME=$ZBR_HOSTNAME
    export ZBR_PORT=$ZBR_PORT

  }

  confirm() {
    while true; do
      echo "$1"
      read -p "$2 [y/n]" yn
      case $yn in
      [y]*)
        return 1
        ;;
      [n]*)
        return 0
        ;;
      *)
        echo
        echo "Please answer y (yes) or n (no)."
        echo
        ;;
      esac
    done
  }


BASEDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd ${BASEDIR}

case "$1" in
    setup)
        docker network inspect infra >/dev/null 2>&1 || docker network create infra

        if [[ -z $ZBR_PROTOCOL || -z $ZBR_HOSTNAME || -z $ZBR_PORT ]]; then
          set_global_settings
        fi

	setup

	# update yml, properties etc using valid ZBR_* values

#        echo WARNING! Increase vm.max_map_count=262144 appending it to /etc/sysctl.conf on Linux Ubuntu
#        echo your current value is `sysctl vm.max_map_count`

#        echo Setup finished successfully using $HOST_NAME hostname.
        ;;
    start)
	start
        ;;
    stop)
        stop
        ;;
    restart)
        down
        start
        ;;
    down)
        down
        ;;
    shutdown)
        shutdown
        ;;
    backup)
        backup
        ;;
    restore)
        restore
        ;;
    --help | -h)
        echo_help
        ;;
    *)
        echo "Invalid option detected: $1"
        echo_help
        exit 1
        ;;
esac

