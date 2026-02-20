#!/usr/bin/env bash

set -euo pipefail

git config --global user.email "<email_address>"
git config --global user.name "<username>"
git config --global credential.helper store
