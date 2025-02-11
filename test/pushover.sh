#!/bin/bash
# ./pushover.sh  -t "Pushover via Bash" -m "Pushover message sent with bash from $(hostname -f)" -p1  -s siren -u http://www.google.com -n "Google"

USER_TOKEN=u51fz4cfchudoomcx2swea6v7uikpp

# YOUR APPS TOKENS / UPPERCASE NAME WITH _TOKEN (usage: "-a monitor" uses MONITOR_TOKEN)
MONITOR_TOKEN=agd7nyoxtabvjtqnggjpm821wq1jvg
BACKUP_TOKEN=APP_TOKEN
ALERT_TOKEN=APP_TOKEN
APP_LIST="monitor, backup, alert" # FOR USAGE

APP_ID="monitor" # Default app

# v1.7
# 14-03-2018 : - Request send only necessary fields.
#              - Added message pipe.
#              - Added monospace option.
#              - Default monitor name
# 12-03-2018 : Added image attachment.
# 30-01-2016 : Added -getopts- arguments to set retry/expire.
# 23-04-2015 : HTML markup language option.

VERSION=1.7

usage()
{
cat << EOF

usage: $0 options

Send a notification via pushover.

OPTIONS:
  -a	Application name : "$APP_LIST" (required)
  -m	Message (required)

  -t	Title of your notification
  -d	Send to a specific device name
  -p	Priority of your message : -2 (Silent), -1 (Quiet), 1 (High), 2 (Emergency)
  -s	Sound (https://pushover.net/api#sounds)
  -i  Attach an image (up to 2.5mb)
  -u	URL Link
  -n	URL Title
  -r	Retry (seconds)
  -e	Expire (seconds)

  -f  HTML Format
  -k  Monospace Format
  -x	Debug
  -h	Show this message

EOF
}

ARGS=( -F "user=$USER_TOKEN" )

# MESSAGE PIPE
if [ -p /dev/stdin ]
then
  MESSAGE=$(</dev/stdin)
  ARGS+=( -F "message=$MESSAGE" )
else
  MESSAGE=
fi

TITLE="<empty>"
URL="<empty>"
URL_TITLE="untitled"
PRIORITY=0
RETRY=60
EXPIRE=86400
SOUND="pushover"
HTML=0
MONOSPACE=0
DEVICE="all"
IMAGE=
DEBUG=0

while getopts “hfkvt:r:e:u:n:p:s:m:a:d:i:x” OPTION
do
    case $OPTION in
        t) TITLE=$OPTARG
           ARGS+=( -F "title=$TITLE" ) ;;
        u) URL=$OPTARG
           ARGS+=( -F "url=$URL" ) ;;
        n) URL_TITLE=$OPTARG
           ARGS+=( -F "url_title=$URL_TITLE" ) ;;
        p) PRIORITY=$OPTARG
           ARGS+=( -F "priority=$PRIORITY" ) ;;
        s) SOUND=$OPTARG
           ARGS+=( -F "sound=$SOUND" ) ;;
        f) HTML=1
           ARGS+=( -F "html=$HTML" ) ;;
        k) MONOSPACE=1
           ARGS+=( -F "monospace=$MONOSPACE" ) ;;
        r) [ ! -z $OPTARG ] && RETRY=$OPTARG ;;
        e) [ ! -z $OPTARG ] && EXPIRE=$OPTARG ;;
        d) DEVICE=$OPTARG
           ARGS+=( -F "device=$DEVICE" ) ;;
        i) IMAGE="$OPTARG"
           ARGS+=( -F "attachment=@${IMAGE}" ) ;;
        a)
           APP_ID="$OPTARG"
        ;;
        m)
           if [[ -z $MESSAGE ]]
           then
             MESSAGE=$OPTARG
             ARGS+=( -F "message=$MESSAGE" )
           fi
           ;;
        v) echo "Pushover shell script version ${VERSION}" && exit 1 ;;
        x) DEBUG=1 ;;
        :) echo "Option -$OPTARG requires an argument." >&2; exit 1 ;;
        h) usage; exit 1 ;;
        ?) usage; exit ;;
    esac
done

# APP TOKEN
if [[ ! -z $APP_ID ]]
then
  APP_ID=`echo $APP_ID | tr '[:lower:]' '[:upper:]'`
  APP_NAME="${APP_ID}_TOKEN"
  APP_TOKEN="${!APP_NAME}"
  ARGS+=( -F "token=$APP_TOKEN" )
fi

# EMERGENCY PRIORITY
if [[ $PRIORITY == 2 ]]
then
  ARGS+=( -F "retry=$RETRY" )
  ARGS+=( -F "expire=$EXPIRE" )
fi

# REQUIRED FIELDS
if [[ -z $MESSAGE ]] || [[ -z $APP_TOKEN ]]
then
  echo -e "\n\\033[31mMessage and Application token are required.\\033[0m"
  usage
  exit 1
fi

# DEBUG PRINT
if [[ $DEBUG == 1 ]]
then
  echo "TITLE ...... $TITLE"
  echo "DEVICE ..... $DEVICE"
  echo "URL ........ ${URL} (${URL_TITLE})"
  echo "FORMAT ..... HTML ${HTML} MONOSPACE ${MONOSPACE}"
  echo "APP ........ ID:${APP_ID} TOKEN:${APP_TOKEN}"
  echo "PRIORITY ... $PRIORITY"
  if [[ $PRIORITY == 2 ]]
  then
  echo "RETRY ...... $RETRY"
  echo "EXPIRE ..... $EXPIRE"
  fi
  echo "SOUND ...... $SOUND"
  echo "IMAGE  ..... $IMAGE"
  echo "MESSAGE -----------------------------------------"
  echo "${MESSAGE}"
  echo "-------------------------------------------------"
  exit 0
fi

# SEND NOTIFICATION
curl -s "${ARGS[@]}" https://api.pushover.net/1/messages.json
