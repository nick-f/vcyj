#!/usr/bin/env bash

source ./root.sh

scripts.pull() {
	scripts=$(api_request "v1/scripts")

	echo "Number of scripts: $(count_total_objects "$scripts")"

	echo "$scripts" | jq -r '.results' | jq -c '.[]' | while read -r script; do
		local filename; filename=$(echo "$script" | jq -r '.name')

		# Get all the attributes of the script except the script contents.
		script_parameters=$(echo "$script" | jq -c 'to_entries[] | select(.key != "scriptContents")')
		script_metadata=$(scripts.compose_metadata "$script_parameters")

		log_info "Updating scripts/$filename"

		# Add the scriptContents to the local file
		echo "$script" | jq -r '.scriptContents' > "scripts/$filename"

		# Add the script metadata to the bottom of the local script file
		echo "$script_metadata" >> "scripts/$filename"
	done
}


scripts.compose_metadata() {
	local raw_metadata; raw_metadata="$1"

	# Massage the metadata into the format that we want.
	# The jq option `-c` is used to compact each value onto one line. The
	# downside of this over `-r` is that `-c` encloses the string in double
	# quotes.
	# The sed command strips the double quotes from the start and the end of the
	# string only.
	#
	# This really only applies to the Notes field which can be multiple lines in Jamf.
	value=$(echo "$raw_metadata" | jq -c '"# \(.key): \(.value)"' | sed -e 's/^"//' -e 's/"$//')
	echo ""
	echo "#------- SCRIPT METADATA BEGIN -------"
	echo "$value"
	echo "#------- SCRIPT METADATA END -------"
}
