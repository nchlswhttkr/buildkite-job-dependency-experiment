#!/bin/bash

set -euo pipefail

curl --fail -X POST "https://api.buildkite.com/v2/organizations/nchlswhttkr/pipelines/website/builds" \
    -H "Authorization: Bearer $BUILDKITE_AGENT_ACCESS_TOKEN"
    -d '{
        "commit": "HEAD",
        "branch": "master"
    }'
