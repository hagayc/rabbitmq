#!/bin/bash
set -e

if [ "$EUID" != 0 ] ; then
        echo "Please run as root (use sudo)"
        exit
fi

### Main Admin User ###
RABBIT_ADMIN=dev1
RABBIT_ADMIN_PASSWD=poopoopoo

### TP User ###
RABBIT_TP_USER=dev2
RABBIT_TP_PASSWD=poopoopoo

### Declared Users ###
USERS=("$RABBIT_ADMIN" "$RABBIT_TP_USER")

### RabbitMQ Virtual Hosts ###
VHOSTS=("DevHost_e2e" "DevHost" "DateTimeCenterSimHost")

### RabbitMQ container name ###
CONTAINER_NAME="$(sudo docker ps | grep rabbit  | awk '{print $1}')"

### Array of RabbitMQ users and their vhost permissions ###
USERS=(
  "$RABBIT_ADMIN:$RABBIT_ADMIN_PASSWD:DevHost"
  "$RABBIT_TP_USER:$RABBIT_TP_PASSWD:DevHost_e2e"
)

for user_info in "${USERS[@]}"; do
  IFS=':' read -ra user <<< "$user_info"
  username="${user[0]}"
  password="${user[1]}"
  vhost="${user[2]}"

### Check if the user exists ###
  if docker exec "${CONTAINER_NAME}" rabbitmqctl list_users | grep -q "^${username}"; then
    echo "User ${username} already exists."
  else
### Create the user ###
    docker exec "${CONTAINER_NAME}" rabbitmqctl add_user "${username}" "${password}"
    docker exec "${CONTAINER_NAME}" rabbitmqctl set_user_tags "${username}" administrator
    echo "User ${username} created successfully."
  fi

### Set vhost permissions ###
  docker exec "${CONTAINER_NAME}" rabbitmqctl set_permissions -p "${vhost}" "${username}" ".*" ".*" ".*"
  echo "Permissions set for user ${username} on vhost ${vhost}."
done
