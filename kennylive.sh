#!/bin/bash


LAUNCHFILE="examples/ex1/app.sh"
# if you want more debug information, put something in $DEBUG variable below
DEBUG="qwe"

. kenny.sh # includes kenny.sh file


while getopts ":pd" opt; do
    case ${opt} in
    p)
        shift
        PORT=$@
        ;;
    d)
        shift
        SERVDIR=$@
        ;;
    \?) echo "Usage: kenny [-p port ] [-d dir]" ;;
    esac
done

kennylisten() {

    if [ -z "$1" ]; then
        PORT=3000
    elif [ "$1" -eq "$1" ] 2>/dev/null; then
        PORT=$1
    else
        log "incorect port: $1" && exit 1
    fi

    PIPE="/tmp/kenny@$PORT"
    log $PIPE
    rm -f $PIPE
    mkfifo $PIPE
    trap kennydie INT
    trap kennydie EXIT

    # echo $PORT
    log $PORT

    # read -r request
    # request=${request%%$'\r'}
    # echo $request >&2
    if [[ -z "$DEBUG" ]]; then
        socat TCP4-LISTEN:${PORT},fork EXEC:"bash $LAUNCHFILE"
    else
        socat TCP4-LISTEN:${PORT},fork EXEC:"bash -x $LAUNCHFILE"
    fi
    # socat TCP4-LISTEN:${PORT},fork EXEC:"./serv.sh",reuseaddr,keepalive
}

kennylisten 3000
