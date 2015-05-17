#!/bin/sh

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

gitcan "rename series" series rename 3.0 4.0
gitcant "rename series when the format is invalid" series rename 4.0 blurp
gitcant "rename series that doesn't exist" series rename 3.0 4.0
gitcant "rename series with a release" series rename 1.0 1.1
gitcan "rename series with a release with -f" series rename -f 1.0 1.1

wrapup
