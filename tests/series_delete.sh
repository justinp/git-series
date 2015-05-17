#!/bin/bash

# git-series - Copyright 2015 Justin Patterson - All Rights Reserved

. $(dirname $0)/common-test.sh

qgit series create 1.0
qgit release create 1.0.0
qcommit

qgit series create 2.0
qgit co series/2.0
qcommit
qgit release create 2.0.0

qgit co master
qgit series create 3.0
qcommit

gitcan "delete series" series delete 3.0
gitcant "delete series when the format is invalid" series delete blurp
gitcant "delete series that doesn't exist" series delete 3.0
gitcant "delete series with a release" series delete 1.0
gitcan "delete series with a release with -f" series delete -f 1.0
gitcant "delete series that has not been merged (git error)" series delete 2.0
gitcant "delete series that has not been merged even with -f (git error)" series delete -f 2.0

wrapup
