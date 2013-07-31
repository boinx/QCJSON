#!/bin/sh

#  BXRevision.sh
#  QCJSON
#
#  Created by Michael Ehrmann on 31.07.13.
#  Copyright (c) 2013 Boinx Software. All rights reserved.


CODE_DIR=$(dirname $0)
CODE_DIR=$(dirname "${CODE_DIR}")

echo ${CODE_DIR}

REV_SHA1=`git --git-dir="${CODE_DIR}/.git" rev-list --max-count=1 HEAD`
GIT_REV=`git --git-dir="${CODE_DIR}/.git" rev-list --reverse HEAD | grep -n ${REV_SHA1} | cut -d: -f1`

echo BX_BUILD_NUMBER = $(( ${GIT_REV}+10000 )) > "${CODE_DIR}/Config/BuildNumber.xcconfig"