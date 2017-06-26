#!/bin/sh

source "/opt/.deploy-meza/config.sh"

if [ -z "$1" ]; then
	do_wikis="*/"
else
	do_wikis="$1"
fi

wiki_dir="$m_htdocs/wikis"

cd "$wiki_dir"
for d in $do_wikis; do

	if [ -z "$1" ]; then
		wiki_id=${d%/}
	else
		wiki_id="$d"
	fi

	if [ ! -d "$wiki_dir/$wiki_id" ]; then
		echo "\"$wiki_id\" not a valid wiki ID"
		continue
	fi

	timestamp=$(date +"%F_%T")
	exception_log="$m_logs/smw-rebuilddata-exceptions-$wiki_id-$timestamp.log"
	out_log="$m_logs/smw-rebuilddata-out.$wiki_id.$timestamp.log"

	echo "Start rebuilding SMW data for \"$wiki_id\" at $timestamp"
	echo "  Exception log (if req'd):"
	echo "    $exception_log"
	echo "  Output log:"
	echo "    $out_log"

	WIKI="$wiki_id" \
	php "$m_mediawiki/extensions/SemanticMediaWiki/maintenance/rebuildData.php" \
	-d 5 -v --ignore-exceptions \
	--exception-log="$exception_log" \
	> "$out_log" 2>&1

	endtimestamp=$(date +"%F_%T")

	# If the above command had a failing exit code
	if [[ $? -ne 0 ]]; then

		# FIXME: add notification/warning system here
		echo "rebuildData FAILED for \"$wiki_id\" at $endtimestamp"

	#if the above command had a passing exit code (e.g. zero)
	else
		echo "rebuildData completed for \"$wiki_id\" at $endtimestamp"
	fi

done
