#!/bin/bash

# git-series - Copyright 2015 Justin Patterson - All Rights Reserved

. $(dirname $0)/common-test.sh

gitcan "create series" series create 0.1
qcommit
qgit tag m1
qcommit
qgit series create 1.0
qcommit
qgit series create 1.1
gitcan "create series with a location" series create 0.2 m1

seriesShouldBe 0.1 0.2 1.0 1.1

shouldCoexist series/0.2 m1

qgit co series/0.2
qcommit
qgit release create 0.2.0
qgit co master
qgit branch -D series/0.2

gitcant "create series when the format is invalid" series create blurp
gitcant "create series when the series already exists" series create 0.2
gitcant "create series at a nonexistent location" series create 0.2 blurp
gitcant "create series when the last release wouldn't descend from the location (HEAD)" series create 0.2
qgit co release/0.2.0
gitcant "create series when the last release wouldn't descend from the location" series create 0.2 master
qgit co master
gitcan "create series anywhere with -f" series create -f 0.2

wrapup
