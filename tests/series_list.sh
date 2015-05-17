#!/bin/bash

# git-series - Copyright 2015 Justin Patterson - All Rights Reserved

. $(dirname $0)/common-test.sh

seriesShouldBe

qgit series create 0.1

seriesShouldBe 0.1

qcommit
qgit series create 1.0

seriesShouldBe 0.1 1.0

qcommit
qgit co series/0.1
qcommit

qgit series create 0.2
qgit release create 0.2.0

seriesShouldBe 0.1 0.2 1.0
qcommit

qgit series delete -f 0.2

seriesShouldBe 0.1 1.0

impliedSeriesShouldBe 0.1 0.2 1.0

wrapup