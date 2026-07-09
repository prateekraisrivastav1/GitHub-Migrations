#!/bin/bash

ORG="ClientCoLtd"
CSV_OUTPUT="github_rulesets_inventory.csv"
JSON_OUTPUT="github_rulesets_details.json"

REPO_LIST=$(gh repo list "$ORG" --json name -q '.[].name' --limit 1000)

echo "org_name, repo_name, ruleset_name, target, enforcement, self_url" > "$CSV_OUTPUT"
echo "[" > "$JSON_OUTPUT"
FIRST=true
for REPO in $REPO_LIST; do
    echo "CHECKING REPOSITORY: $REPO"

    RULESETS_API=$(gh api repos/${ORG}/${REPO}/rulesets)
    if [ $? -ne 0 ] || [ -z "$RULESETS_API" ] || [ "$RULESETS_API" = "[]" ]; then
        echo "No rulesets found or API error: $REPO"
        continue
    fi
    echo "$RULESETS_API" | jq -c '.[]' |
    while read -r RULESET; do

        NAME=$(echo "$RULESET" | jq -r '.name')
        TARGET=$(echo "$RULESET" | jq -r '.target')
        ENFORCEMENT=$(echo "$RULESET" | jq -r '.enforcement')
        SELF_URL=$(echo "$RULESET" | jq -r '._links.self.href')

        echo "Found Ruleset: $NAME"
        echo "\"$ORG\",\"$REPO\",\"$NAME\",\"$TARGET\",\"$ENFORCEMENT\",\"$SELF_URL\"" >> "$CSV_OUTPUT"

        DETAILS=$(gh api "$SELF_URL")
         if [ -n "$DETAILS" ]; then
            if [ "$FIRST" = true ]; then
                FIRST=false
            else
                echo "," >> "$JSON_OUTPUT"
            fi
            echo "$DETAILS" >> "$JSON_OUTPUT"
        fi
        echo "$DETAILS" >> "$JSON_OUTPUT"
    done
done

echo "]" >> "$JSON_OUTPUT"

echo "Completed:"
echo "CSV: $CSV_OUTPUT"
echo "JSON: $JSON_OUTPUT"

echo "Completed: $CSV_OUTPUT"