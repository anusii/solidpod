#!/bin/bash

cat coverage/lcov.info |
    egrep '^(SF|LF|LH)' |
    awk '{gsub(/^(SF:|LF:|LH:)/, "", $0); print}' |
    awk 'ORS=NR%3?",":"\n"' |
    awk -F',' 'BEGIN { linesTotal=0; hitsTotal=0; }
                     { linesTotal+=$2; hitsTotal+=$3; print $0; }
               END   { printf "total,%d,%d\n", linesTotal, hitsTotal; }' |
    awk 'BEGIN{ print("file,lines,hits") } {print}' |
    mlr --csv put '$cover = round(100*$hits/$lines)' |
    tee coverage/coverage.csv |
    mlr --csv --opprint --barred cat

cover=$(mlr --csv filter '$file=="total"' then cut -f cover coverage/coverage.csv | tail +2)

if [ "$cover" -lt 90 ]; then
    echo -e "\nThe code coverage is too low: ${cover}%. Expected at least 90%."
    exit 1
fi
