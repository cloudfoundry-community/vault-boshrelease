#!/bin/bash

set -e

# change to root of bosh release
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd $DIR/../..

cat > ~/.bosh_config << EOF
---
aliases:
  target:
    bosh-lite: ${bosh_target}
auth:
  ${bosh_target}:
    username: ${bosh_username}
    password: ${bosh_password}
EOF
bosh target ${bosh_target}

cat > config/private.yml << EOF
---
blobstore:
  s3:
    access_key_id: ${aws_access_key_id}
    secret_access_key: ${aws_secret_access_key}
EOF

_bosh() {
  bosh -n $@
}

set -e

version=$(cat ../version/number)
if [ -z "$version" ]; then
  echo "missing version number"
  exit 1
fi
if [[ "${release_name}X" == "X" ]]; then
  echo "missing \$release_name"
  exit 1
fi

echo Prepare github release information
set -x
mkdir -p release
cp ci/release_notes.md release/notes.md
echo "${release_name} v${version}" > release/name
echo "v${version}" > release/tag
cat > release/slack_success_message.txt <<EOS
<!here> New version v${version} released
EOS

git config --global user.email "drnic+bot@starkandwayne.com"
git config --global user.name "Stark and Wayne CI Bot"

git merge --no-edit ${promotion_branch}


bosh target ${BOSH_TARGET}

bosh -n create release --final --with-tarball --version "$version"

git add -A
git commit -m "release v${version}"
