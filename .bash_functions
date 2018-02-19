if which tput >/dev/null 2>&1; then
    RED=$(    tput setaf 1)
    GREEN=$(  tput setaf 2)
    YELLOW=$( tput setaf 3)
    BLUE=$(   tput setaf 4)
    PURPLE=$( tput setaf 5)
    CYAN=$(   tput setaf 6)
    RESET=$(  tput sgr0   )
else
    # Cygwin
    RED='\e[1;31m'
    GREEN='\e[1;32m'
    YELLOW='\e[1;33m'
    BLUE='\e[1;34m'
    PURPLE='\e[1;35m'
    CYAN='\e[1;36m'
    RESET='\e[0m'
fi

info() {
    NOTE="$*"
    echo "-->$GREEN $NOTE $RESET"
}

debug() {
    NOTE="$*"
    echo "---->$PURPLE $NOTE $RESET"
}

header() {
    NOTE="$*"
    echo "----$YELLOW $NOTE $RESET----"
}

warning() {
    NOTE="$*"
    echo "----$RED $NOTE $RESET----"
}

success() {
    echo "----$YELLOW SUCCESS!$GREEN Took $SECONDS seconds $RESET----"
}

failure() {
    echo "----$RED FAILURE!$GREEN Took $SECONDS seconds $RESET----"
}
