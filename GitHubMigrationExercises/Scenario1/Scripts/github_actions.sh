#!/bin/bash

ORG="ClientCoLtd"
OUTPUT="github_actions_inventory.csv"


# Environment Secrets Section
echo "scope,repo_name,env_name,type,feature,name" > "$OUTPUT"

REPO_LIST=$(gh repo list "$ORG" --json name -q '.[].name' --limit 1000)

for REPO in $REPO_LIST; do
    echo "Checking environments for repository: $REPO"
    ENVIRONMENTS=$(gh api \
        "repos/${ORG}/${REPO}/environments" \
        --jq '.environments[].name' 2>/dev/null)

    for ENV in $ENVIRONMENTS; do

        echo "Checking environment: $ENV"

        gh api \
            "repos/${ORG}/${REPO}/environments/${ENV}/secrets" \
            --jq '.secrets[].name' 2>/dev/null |
        while read -r NAME; do
            echo "repo,$REPO,$ENV,secret,actions,$NAME" >> "$OUTPUT"
        done
    done
done

# Repository + Organization Actions Section

echo "" >> "$OUTPUT"
echo "scope,org_name,repo_name,type,feature,name" >> "$OUTPUT"

# Repository Actions Secrets & Variables
for REPO in $REPO_LIST; do

    echo "Checking repository Actions: $REPO"
   # Repository Secrets
    gh api \
        "repos/${ORG}/${REPO}/actions/secrets" \
        --jq '.secrets[].name' 2>/dev/null |
    while read -r NAME; do
        echo "repo,$ORG,$REPO,secret,actions,$NAME" >> "$OUTPUT"
    done

    # Repository Variables
    gh api \
        "repos/${ORG}/${REPO}/actions/variables" \
        --jq '.variables[].name' 2>/dev/null |
    while read -r NAME; do

        echo "repo,$ORG,$REPO,variable,actions,$NAME" >> "$OUTPUT"
    done
done

# Organization Actions Secrets & Variables
echo "Checking organization Actions"

# Organization Secrets
gh api \
    "orgs/${ORG}/actions/secrets" \
    --jq '.secrets[].name' 2>/dev/null |
while read -r NAME; do

    echo "org,$ORG,,secret,actions,$NAME" >> "$OUTPUT"

done



# Organization Variables
gh api \
    "orgs/${ORG}/actions/variables" \
    --jq '.variables[].name' 2>/dev/null |
while read -r NAME; do

    echo "org,$ORG,,variable,actions,$NAME" >> "$OUTPUT"

done



echo "Completed: $OUTPUT"