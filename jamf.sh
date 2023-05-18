#!/usr/bin/env bash

username="your.username"
password="your.password"
url="https://example.jamfcloud.com"

bearer_token=""
token_expiration_epoch="0"

get_bearer_token() {
	response=$(curl -s -u "$username":"$password" "$url"/api/v1/auth/token -X POST)
	bearer_token=$(echo "$response" | plutil -extract token raw -)
	token_expiration=$(echo "$response" | plutil -extract expires raw - | awk -F . '{print $1}')
	token_expiration_epoch=$(date -j -f "%Y-%m-%dT%T" "$token_expiration" +"%s")
}

check_token_expiration() {
	nowEpochUTC=$(date -j -f "%Y-%m-%dT%T" "$(date -u +"%Y-%m-%dT%T")" +"%s")
	if [[ token_expiration_epoch -gt nowEpochUTC ]]
	then
		echo "Token valid until the following epoch time: " "$token_expiration_epoch"
	else
		echo "No valid token available, getting new token"
		get_bearer_token
	fi
}

api_request() {
	check_token_expiration 1>&2

	curl -s -X GET \
		--url "$url/api/v1/scripts?page=0&page-size=100&sort=name%3Aasc" \
		--header 'accept: application/json' \
		-H "Authorization: Bearer ${bearer_token}"
}

invalidateToken() {
	response_code=$(curl -w "%{http_code}" -H "Authorization: Bearer ${bearer_token}" $url/api/v1/auth/invalidate-token -X POST -s -o /dev/null)

	if [[ ${response_code} == 204 ]]
	then
		echo "Token successfully invalidated"
		bearer_token=""
		token_expiration_epoch="0"
	elif [[ ${response_code} == 401 ]]
	then
		echo "Token already invalid"
	else
		echo "An unknown error occurred invalidating the token"
	fi
}
