#!/bin/bash
# auhtor: Mauricio Pasten (mrp4sten)

# Global Variables
UNCONFIRMED_TRANSACTIONS="https://www.blockchain.com/explorer/mempool/btc"
REG_EX_HASH="[a-fA-F0-9]{64}"
REG_EX_DECIMAL="\d+\.\d+"

# Colours
greenColour="\e[0;32m\033[1m"
endColour="\033[0m\e[0m"
redColour="\e[0;31m\033[1m"
blueColour="\e[0;34m\033[1m"
yellowColour="\e[0;33m\033[1m"
purpleColour="\e[0;35m\033[1m"
turquoiseColour="\e[0;36m\033[1m"
grayColour="\e[0;37m\033[1m"

# to CTRL + C
trap ctrl_c INT

# functions
function ctrl_c() {
    echo -e "\n${redColour} [!] Exiting...\n ${endColour}"
    tput cnorm
    rm *.tmp 2>/dev/null
    exit 1
}

function helpPanel() {
    echo -e "\n${redColour} [!] Use: ./btcAnalyzer.sh ${endColour}"
    for i in $(seq 1 80); do
        echo -ne "${redColour}-"
    done
    echo -ne "${endColour}"
    echo -e "\n\n ${grayColour} [-e] ${endColour} ${yellowColour} Exploration Mode ${endColour}"
    echo -e "\t\t ${purpleColour} unconfirmed_transactions ${endColour} ${yellowColour}:\t List Unconfirmed Transactions ${endColour}"
    echo -e "\t\t ${purpleColour} inspect ${endColour} ${yellowColour}:\t\t\t Inspect a Hash Transaction ${endColour}"
    echo -e "\t\t ${purpleColour} address ${endColour} ${yellowColour}:\t\t\t Inspect Address Transaction ${endColour}"
    echo -e "\n\n ${grayColour} [-h] ${endColour} ${yellowColour} Display Help Pane ${endColour}"

    tput cnorm
    exit 1
}

function printTable() {
    local -r delimiter="${1}"
    local -r data="$(removeEmptyLines "${2}")"

    if [[ "${delimiter}" != '' && "$(isEmptyString "${data}")" = 'false' ]]; then
        local -r numberOfLines="$(wc -l <<<"${data}")"

        if [[ "${numberOfLines}" -gt '0' ]]; then
            local table=''
            local i=1

            for ((i = 1; i <= "${numberOfLines}"; i = i + 1)); do
                local line=''
                line="$(sed "${i}q;d" <<<"${data}")"

                local numberOfColumns='0'
                numberOfColumns="$(awk -F "${delimiter}" '{print NF}' <<<"${line}")"

                if [[ "${i}" -eq '1' ]]; then
                    table="${table}$(printf '%s#+' "$(repeatString '#+' "${numberOfColumns}")")"
                fi

                table="${table}\n"

                local j=1

                for ((j = 1; j <= "${numberOfColumns}"; j = j + 1)); do
                    table="${table}$(printf '#| %s' "$(cut -d "${delimiter}" -f "${j}" <<<"${line}")")"
                done

                table="${table}#|\n"

                if [[ "${i}" -eq '1' ]] || [[ "${numberOfLines}" -gt '1' && "${i}" -eq "${numberOfLines}" ]]; then
                    table="${table}$(printf '%s#+' "$(repeatString '#+' "${numberOfColumns}")")"
                fi
            done

            if [[ "$(isEmptyString "${table}")" = 'false' ]]; then
                echo -e "${table}" | column -s '#' -t | awk '/^\+/{gsub(" ", "-", $0)}1'
            fi
        fi
    fi
}

function removeEmptyLines() {
    local -r content="${1}"
    echo -e "${content}" | sed '/^\s*$/d'
}

function repeatString() {
    local -r string="${1}"
    local -r numberToRepeat="${2}"

    if [[ "${string}" != '' && "${numberToRepeat}" =~ ^[1-9][0-9]*$ ]]; then
        local -r result="$(printf "%${numberToRepeat}s")"
        echo -e "${result// /${string}}"
    fi
}

function isEmptyString() {
    local -r string="${1}"

    if [[ "$(trimString "${string}")" = '' ]]; then
        echo 'true' && return 0
    fi

    echo 'false' && return 1
}

function trimString() {
    local -r string="${1}"
    sed 's,^[[:blank:]]*,,' <<<"${string}" | sed 's,[[:blank:]]*$,,'
}

function unconfirmedTransactions() {
    echo '' >unconfirmed_transactions.tmp

    while [ "$(cat unconfirmed_transactions.tmp | wc -l)" == "1" ]; do
        curl -s "$UNCONFIRMED_TRANSACTIONS" | html2text >unconfirmed_transactions.tmp
    done

    # [a-fA-F0-9] is the REGEX used to find a HASH
    # {64} is used to specify that the pattern should have 64 characters
    hash_list=$(cat unconfirmed_transactions.tmp | grep "Unconfirmed BTC Transactions" -A 36 | grep -o -E $REG_EX_HASH)

    echo "Hash_BTC_USD" >unconfirmed_transactions.table.tmp

    for hash_item in $hash_list; do
        # date_time=$(cat unconfirmed_transactions.tmp | grep "${hash_item}" -B 1 | grep -o -P '\d{1,2}/\d{1,2}/\d{4}, \d{2}:\d{2}:\d{2}')
        btc_value=$(cat unconfirmed_transactions.tmp | grep "${hash_item}" | grep -o -P $REG_EX_DECIMAL)
        usd_value=$(echo "29401.82 * ${btc_value}" | bc)
        echo "${hash_item}_${btc_value}_${usd_value}" >>unconfirmed_transactions.table.tmp
    done

    echo -ne "${yellowColour}"
    printTable "_" "$(cat unconfirmed_transactions.table.tmp)"
    echo -ne "${endColour}"

    rm *.tmp 2>/dev/null

    tput cnorm
}

parameter_counter=0

while getopts "e:h:" arg; do
    case $arg in
    e)
        exploration_mode=$OPTARG
        let parameter_counter+=1
        ;;
    h) helpPanel ;;
    esac
done

# To Hidde cursor
tput civis

if [ $parameter_counter -eq 0 ]; then
    helpPanel
else
    if [ "$(echo $exploration_mode)" == "unconfirmed_transactions" ]; then
        unconfirmedTransactions
    fi
fi
