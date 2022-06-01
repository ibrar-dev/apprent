#!/usr/bin/env bash

echo $GOOGLE_CLOUD_CREDENTIALS > config/gcp.secret.json
echo -n $RENT_APPLY_KEY > config/pub.key
cd crypto
./compile.sh
cd ..
mix deps.get
cd assets
npm install
cd ..
mix compile_mjml
service postgresql start
createuser -drs tester -U postgres
createdb payout_test -U tester
mix ecto.create
mix test
result=$?
if [[ ${result} != 0 ]]; then
    echo "Test suite failure"
    exit 1
fi
MIX_ENV=integration mix test.integration
result2=$?
if [[ ${result2} != 0 ]]; then
    echo "Integration test suite failure"
    exit 1
fi
