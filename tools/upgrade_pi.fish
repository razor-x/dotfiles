#!/usr/bin/env fish

cd home/dot_config/pi/extensions/exact_local
or exit

set --function pi_info (npm view --json \
    @earendil-works/pi-coding-agent@latest \
    dependencies devDependencies engines version | string collect)
test $pipestatus[1] -eq 0
or exit

set --function pi_version (printf '%s\n' "$pi_info" | jq --raw-output '.[0].version')
or exit

curl \
    --fail \
    --silent \
    --show-error \
    --location \
    "https://raw.githubusercontent.com/earendil-works/pi/v$pi_version/tsconfig.base.json" \
    --output tsconfig.base.json
or exit

set --function typescript_version (printf '%s\n' "$pi_info" | jq --raw-output '.[0].devDependencies.typescript')
or exit
set --function node_types_version (printf '%s\n' "$pi_info" | jq --raw-output '.[0].devDependencies["@types/node"]')
or exit
set --function typebox_version (printf '%s\n' "$pi_info" | jq --raw-output '.[0].dependencies["typebox"]')
or exit
set --function ai_version (printf '%s\n' "$pi_info" | jq --raw-output '.[0].dependencies["@earendil-works/pi-ai"]')
or exit
set --function tui_version (printf '%s\n' "$pi_info" | jq --raw-output '.[0].dependencies["@earendil-works/pi-tui"]')
or exit
set --function engines (printf '%s\n' "$pi_info" | jq --compact-output '.[0].engines')
or exit

set --function package_json (mktemp package.json.XXXXXX)
or exit
trap (string join ' ' -- rm --force (string escape -- "$package_json")) EXIT

jq \
    --arg pi_version "$pi_version" \
    --arg ai_version "$ai_version" \
    --arg tui_version "$tui_version" \
    --arg typebox_version "$typebox_version" \
    --arg node_types_version "$node_types_version" \
    --arg typescript_version "$typescript_version" \
    --argjson engines "$engines" \
    '
      .name = "pi-local-extension"
      | .engines = $engines
      | .devDependencies["@earendil-works/pi-ai"] = $ai_version
      | .devDependencies["@earendil-works/pi-coding-agent"] = $pi_version
      | .devDependencies["@earendil-works/pi-tui"] = $tui_version
      | .devDependencies["@types/node"] = $node_types_version
      | .devDependencies["typebox"] = $typebox_version
      | .devDependencies["typescript"] = $typescript_version
    ' \
    package.json >"$package_json"
or exit

mv "$package_json" package.json
or exit
trap - EXIT

npm install
or exit
npm run typecheck
or exit
npm --prefix ../../exact_npm update
