#!/bin/bash

cd "$(dirname "$0")" || exit 1

set -ue
RUNS_FILE=$1

declare -a name_array=()

cleanup_all() {
    set -ux
    # cleanup all resource groups
    for name in "${name_array[@]}"; do
        ./cleanup.sh "$name" &
    done
    wait
}

clean_exit() {
    trap "cleanup_all" TERM
    # kill all processes in the current process group, this is uncluding
    # ourselves. That's why we set another trap right before.
    kill 0
}

trap "exit" INT TERM
trap 'clean_exit' EXIT

set -x
while read -r line; do
    # skip empty lines
    if [ -z "$line" ]; then
        continue
    fi

    IFS=',' read -r -a split_line <<< "$line"

    for i in $(seq "${split_line[0]}"); do
        name=$USER-hammerdb-$(openssl rand -hex 12)-$i
        name_array+=("$name")

        # If one of these fails, continue with the rest
        set +e
        set -x
        ./run-benchmark.sh "$name" "${split_line[@]:1}" &
        set +x
        set -e
    done
done < "$RUNS_FILE"
wait
exit