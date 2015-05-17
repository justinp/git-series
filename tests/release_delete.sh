#!/bin/sh

. $(dirname $0)/common-test.sh

gitcant "delete release with invalid format" release delete 1.0
gitcant "delete release that doesn't exist" release delete 1.0.0

qgit series create 1.0
qgit co series/1.0
qcommit
qgit release create 1.0.0
qcommit
qgit release create 1.0.1
qcommit
qgit release create 1.0.2
qcommit
qgit release create 1.0.3
qcommit
qgit release create 1.0.4
qcommit
qgit release create 1.0.5
qcommit
qgit release create 1.0.6
qcommit
qgit release create 1.0.7
qcommit
qgit co master
qgit series create 2.0
qgit co series/2.0
qcommit
qgit release create 2.0.0
qcommit
qgit release create 2.0.1
qcommit
qgit release create 2.0.2
qcommit

shouldCoexist release/1.0.x release/1.0.7
shouldCoexist release/2.0.x release/2.0.2

gitcan "delete a release that's the latest" release delete 1.0.7
shouldCoexist release/1.0.x release/1.0.6

gitcan "delete a release that's not the latest" release delete 1.0.6
shouldCoexist release/1.0.x release/1.0.5

gitcan "delete multiple releases at once" release delete 1.0.5 1.0.2
shouldCoexist release/1.0.x release/1.0.4

gitcan "delete multiple releases from different series at once" release delete 1.0.4 2.0.2
shouldCoexist release/1.0.x release/1.0.3
shouldCoexist release/2.0.x release/2.0.1

wrapup
