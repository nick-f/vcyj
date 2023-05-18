#!/usr/bin/env bash

source ./jamf.sh

count_total_objects() {
	echo "$1" | jq '.totalCount'
}

log() {
	echo "--- $1"
}

log_info() {
	log "INFO: $1"
}

# main
