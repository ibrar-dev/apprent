#!/usr/bin/env bash

echo $GOOGLE_CLOUD_CREDENTIALS > config/gcp.secret.json
mkdir -p priv/static
cd crypto
./compile.sh
cd ..
mix deps.get --only prod
cd assets
npm install
npm run build
result=$?
if [[ ${result} != 0 ]]; then
    echo "NPM build error"
    exit 1
fi
cd ..
mix phx.digest
mix compile_mjml
result2=$?
if [[ ${result2} != 0 ]]; then
    echo "MJML Compile error"
    exit 1
fi
mix compile --warnings-as-errors
result3=$?
if [[ ${result3} != 0 ]]; then
    echo "Please fix compiler warnings"
    exit 1
fi
mix release
cd _build/prod/rel
tar -czf /app_count.tar.gz app_count