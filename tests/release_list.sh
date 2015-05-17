#!/bin/bash

# git-series - Copyright 2015 Justin Patterson - All Rights Reserved

. $(dirname $0)/common-test.sh

releasesShouldBe

qgit series create 0.1
qgit co series/0.1

releasesShouldBe

qgit release create 0.1.0

releasesShouldBe 0.1.0

qcommit
qgit release create 0.1.1

releasesShouldBe 0.1.0 0.1.1

qgit series create 1.0
qgit co series/1.0

qgit release create 1.0.0

releasesShouldBe 0.1.0 0.1.1 1.0.0

qcommit
qgit release create -f 1.0.2

qgit series create 0.2

qgit release create -f 0.2.2

releasesShouldBe 0.1.0 0.1.1 0.2.2 1.0.0 1.0.2

wrapup

