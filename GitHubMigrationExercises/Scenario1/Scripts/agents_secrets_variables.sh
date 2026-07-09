#!/bin/bash

ORG="ClientCoLtd"
OUTPUT="github_agents_inventory.csv"


echo "Scope, Repo/Org Name, Feature, Type , Name" > "$OUTPUT"


REPO_LIST=$(gh repo list "$ORG" --json name -q '.[].name' --limit 1000)

echo "Checking repo level secrets and variables for agents"
for REPO in $REPO_LIST; do
    echo "Checking repository: $REPO secrets"
    gh api \
      "repos/${ORG}/${REPO}/agents/secrets" \
      --jq '.secrets[].name' 2>/dev/null |
    while read -r NAME; do
        echo "\"Repository\",\"$REPO\",\"Agents\",\"Secret\",\"$NAME\"" >> "$OUTPUT"
    done
    echo "Checking repository: $REPO variables"
    gh api \
      "repos/${ORG}/${REPO}/agents/variables" \
      --jq '.variables[].name' 2>/dev/null |
    while read -r NAME; do
        echo "\"Repository\",\"$REPO\",\"Agents\",\"Variable\",\"$NAME\"" >> "$OUTPUT"
    done

done

echo "Checking organization level variables for agents"

gh api \
 "orgs/${ORG}/agents/secrets" \
 --jq '.secrets[].name' 2>/dev/null |
while read -r NAME; do
    echo "\"Organization\",\"${ORG}\",\"Agents\",\"Secret\",\"$NAME\"" >> "$OUTPUT"
done

gh api \
"orgs/${ORG}/agents/variables" \
 --jq '.variables[].name' 2>/dev/null |
while read -r NAME; do
    echo "\"Organization\",\"${ORG}\",\"Agents\",\"Variable\",\"$NAME\"" >> "$OUTPUT"
done


echo "Completed: $OUTPUT"