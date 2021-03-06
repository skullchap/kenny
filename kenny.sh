#!/bin/bash

### written by skullchap

urldecode() {
    local v="${1//+/ }" r= d
    while [ -n "$v" ]; do
        if [[ $v =~ ^([^%]*)%([0-9a-fA-F][0-9a-fA-F])(.*)$ ]]; then
            eval d="\$'\x${BASH_REMATCH[2]}'"
            [ "$d" = "$cr" ] && d=
            r="$r${BASH_REMATCH[1]}$d"
            v="${BASH_REMATCH[3]}"
        else
            r="$r$v"
            break
        fi
    done
    echo "$r"
}

urlencode() {
    local length="${#1}" i c
    for ((i = 0; i < length; i++)); do
        c="${1:i:1}"
        case $c in
        [a-zA-Z0-9.~_-]) printf "$c" ;;
        *) printf '%%%02X' "'$c" ;;
        esac
    done
}

log() {
    echo -e "${@}" >&2
}

kennyview() {
    eval "echo \"$(<$1)\""
}

kennyjson() {
    CONTENTTYPE="application/json; charset=UTF-8"
    echo $CONTENTTYPE | kennystatus
    echo "${*}" | jq . -c
    return 0
}

kennystatus() {
    if [[ -z $1 ]]; then
        read -t 0.001 input
        if [[ -z input ]]; then
            return 1
        fi
        CONTENTTYPE=${input}
        kennystatus 200
    fi

    if [ "$1" -eq 200 ]; then
        echo "HTTP/2 200 OK"
        echo "X-Powered-By: Kenny"
        echo -e "Content-Type: $CONTENTTYPE\n"

    elif [ "$1" -eq 400 ]; then
        echo -e "HTTP/1.1 400 Bad Request\n\n<h1>400 Bad Request.</h1>" #>$PIPE
    fi
}

kennydie() {
    rm -f $PIPE && echo -e "\n\tKenny died.\n" && exit
}

declare -a REQUEST_HEADERS
declare -a ROUTES
declare -a PARAMS
declare -A GETROUTESnFUNCS
declare -A POSTROUTESnFUNCS
declare -A GETQUERY

kennyget() {
    PARAMS+=($(echo $1 | grep -oP "(:[A-Za-z0-9\.\*\[\]\^\$\{\}\\\+\?\|\(\)]+)"))
    GETROUTESnFUNCS[$1]=${*:2}
}

kennypost() {
    POSTROUTESnFUNCS[$1]=${*:2}
}

kenny() {
    kennyget $@
    kennypost $@
}

kennylive() {
    kennyparse
    # if [ ${#POSTROUTESnFUNCS[@]} -eq 0 ]; then
    #     log "empty"
    # fi
    # bodyparse
    if [ $? == 0 ]; then
        # if [ $errcode == 0 ]; then
        log $route
        log $method
        log "${REQUEST_HEADERS[@]}"
        [[ ! -z $body ]] && log "$body"
        # kennystatus 200 # needed for kennyjson, this is a bug
        if [[ "$method" == "GET" ]]; then
            ${GETROUTESnFUNCS[$route]}
        elif [[ "$method" == "POST" ]]; then
            ${POSTROUTESnFUNCS[$route]}
        fi

    fi
}

kennyquery() {
    # eval $1="${GETQUERY[$1]}"
    for p in $@; do
        eval $p="${GETQUERY[$p]}"
    done
}

# kennyparam() {
    
# }

# checkforparam() {
# #     PARAMS+=($(echo $1 | grep -oP "(:[A-Za-z0-9\.\*\[\]\^\$\{\}\\\+\?\|\(\)]+)"))
# #     if [[ -z ${PARAMS} ]]; then
# #         return 1
# #     else
# #         return 0
# #     fi

# }

checkforquery() {
    # if [[ "$1" == *"?"* ]]; then
    if [[ "$method" == "GET" ]]; then
        if [[ "$1" == *"?"* ]]; then
            getqueryparse $1
            return 0
        else
            return 1
        fi
    elif [[ "$method" == "POST" ]]; then
        if [[ "$1" == *"="* ]]; then
            postqueryparse $1
            return 0
        else
            return 1
        fi
    fi
}

getqueryparse() {
    query="${1##*\?}"
    route="${1%\?*}"
    IFS='&' read -r -a queryparams <<<"$query"
    for param in ${queryparams[@]}; do
        log $param
        key=${param%%\=*}
        value=${param##*\=}
        GETQUERY[$key]=$value
    done
}

postqueryparse() {
    # if [[ "$contentType" == *"multipart/form-data"* ]]; then
    #     # $contentType=${contentType%%;*}
    # else
    query="$1"
    # route="${1%\?*}"
    IFS='&' read -r -a queryparams <<<"$query"
    for param in ${queryparams[@]}; do
        log $param
        key=${param%%\=*}
        value=${param##*\=}
        GETQUERY[$key]=$value
    done
    # fi
}

checkforfile() {
    reqfilepath="${1#*/}"
    reqfile=${1##*/}
    ext=${reqfile##*.}
    # route=${1%${1##*/}}
    if [[ -f "$reqfilepath" ]]; then
        log "ext=$ext  route=$route reqfile=$reqfile reqfilepath=$reqfilepath"
        if [[ ! -z "$ext" ]]; then
            case "$ext" in
            "html" | "htm") CONTENTTYPE="text/html; charset=UTF-8" ;;
            "json") CONTENTTYPE="application/json; charset=UTF-8" ;;
            "css" | "less" | "sass") CONTENTTYPE="text/css" ;;
            "txt") CONTENTTYPE="text/plain" ;;
            "xml") CONTENTTYPE="text/xml" ;;
            "js") CONTENTTYPE="application/javascript" ;;
            "jpg" | "jpeg") CONTENTTYPE="image/jpeg" ;;
            "png") CONTENTTYPE="image/png" ;;
            "gif") CONTENTTYPE="image/gif" ;;
            "ico") CONTENTTYPE="image/x-icon" ;;
            "wav") CONTENTTYPE="audio/wav" ;;
            "mp3") CONTENTTYPE="audio/mpeg3" ;;
            "avi") CONTENTTYPE="video/avi" ;;
            "mp4" | "mpg" | "mpeg" | "mpe") CONTENTTYPE="video/mpeg" ;;
            *) CONTENTTYPE="application/octet-stream" ;;
            esac
        fi
        return 0
    else
        return 1
    fi

}

checkgetroutes() {
    checkforquery $route #${er/*:/ }
    if [[ " ${!GETROUTESnFUNCS[@]} " =~ " $route " ]]; then
        echo "checked" >&2
        echo "route $route exists" >&2
        kennystatus 200
        return 0
    else
        checkforfile $route
        if [ $? == 0 ]; then
            kennystatus 200
            cat $reqfilepath
            return 0
        else
            kennystatus 400
            echo "$method $route does not exists."
            return 1
        fi
    fi
}

checkpostroutes() {
    # checkforquery $route
    if [[ " ${!POSTROUTESnFUNCS[@]} " =~ " $route " ]]; then
        echo "checked" >&2
        echo "route $route exists" >&2
        kennystatus 200
        return 0
    else
        kennystatus 400
        # reqfile=${route#*/}
        # log "File request:" ${reqfile}
        # cat ${reqfile}
        echo "$method $route does not exists."
        return 1
    fi
}

bodyparse() {
    if [[ $contentlength -gt 0 ]]; then
        if [[ ${contentType} =~ ^multipart/form-data\;[[:space:]]*boundary=([^\;]+) ]]; then
            sep="--${BASH_REMATCH[1]}"
            OIFS="$IFS"
            IFS=$'\r'
            while read -r line; do
                # body+="$line"
                ((bodylen = $bodylen + $(echo $line | wc -c) + 1))
                log "contentlength: "$contentlength
                log "bodylen: "$bodylen

                if [[ $line =~ ^Content-Disposition:\ *form-data\;\ *name=\"([^\"]+)\" ]]; then
                    local key="${BASH_REMATCH[1]}"
                    log "key: "$key

                    read -r line
                    ((bodylen += 2)) # expecting empty line '\r\n'; 2 bytes
                    [ $bodylen -ge $contentlength ] && break

                    continue

                fi
                if [[ "$line" =~ "$sep" ]]; then
                    [ $bodylen -ge $contentlength ] && break
                    continue
                fi
                value="$line"
                log "value: " $value
                checkforquery "$key=$value"

                [ $bodylen -ge $contentlength ] && break

            done

        else

            while true; do
                read -t 0.0001 -r line
                RETVAL=$?
                log $RETVAL
                bodyline="${line%%$'\r'}"
                [ -z "$line" ] && break
                # echo $bodyline

                body+="$bodyline"
                ((bodylen = $bodylen + $(echo $line | wc -c)))
                log "contentlength: "$contentlength
                log "bodylen: "$bodylen
                [ $bodylen -ge $contentlength ] && break

            done
            # if [[ "$contentType" == "application/x-www-form-urlencoded" ]]; then
            #     checkforquery $body
            # fi
            log "$body"
            checkforquery $body
        fi
    fi
}
kennyparse() {
    read -r request
    request=${request%%$'\r'}
    read -r method route http_version <<<$request

    if [[ "$method" == "GET" ]]; then
        checkgetroutes $route
        if [ $? == 0 ]; then
            errcode=0
        else
            errcode=1
        fi
    elif [[ "$method" == "POST" ]]; then
        checkpostroutes $route
        if [ $? == 0 ]; then
            errcode=0
        else
            errcode=1
        fi
    fi

    while read -r header; do
        header="${header%%$'\r'}"
        [ -z "$header" ] && break
        REQUEST_HEADERS+=("${header}")
        [[ "${header}" =~ "Content-Length" ]] && contentlength=${header//[!0-9]/}
        [[ "${header}" =~ "Content-Type" ]] && contentType=${header##*: }
        [[ "${header}" =~ "Cookie" ]] && cookie=${header##*: }
        [[ "${header}" =~ "boundary" ]] && boundary=${header##*: }
    done
    log $contentType

    bodyparse

    return $((errcode))
}
