#!/bin/sh

. $(dirname $0)/common-test.sh

gitcant "create release for a nonexistent series" release create 1.0.0
qgit series create 1.0
qgit co series/1.0
qcommit
gitcant "create release when the format is invalid" release create 1.0
gitcan "create a release" release create 1.0.0
shouldCoexist release/1.0.x release/1.0.0
gitcant "create release that already exists" release create 1.0.0
gitcant "create a release unless it strictly descends from the last" release create 1.0.1
shouldCoexist release/1.0.x release/1.0.0
qcommit
qgit tag m1
qcommit
gitcant "create a release unless it's the next in sequence" release create 1.0.3
shouldCoexist release/1.0.x release/1.0.0
gitcan "create a release out of sequence with -f" release create -f 1.0.3
shouldCoexist release/1.0.x release/1.0.3
gitcant "create a release unless later releases strictly descend from it" release create 1.0.2
qcommit
gitcant "create a release unless later releases descend from it" release create 1.0.2
gitcan "create a release with invalid descent with -f" release create -f 1.0.2
shouldCoexist release/1.0.x release/1.0.3
gitcant "create a release with a nonexistent location" release create -f 1.0.1 m2
gitcan "create a release with a location" release create -f 1.0.1 m1
shouldCoexist release/1.0.1 m1
qgit co -b new
qcommit
gitcant "create a release unless series descends from it" release create 1.0.4
gitcan "create a release off-series with -f" release create -f 1.0.4
shouldCoexist release/1.0.x release/1.0.4
qgit co series/1.0
qcommit
gitcan "create another release back on-series with -f " release create -f 1.0.5
shouldCoexist release/1.0.x release/1.0.5
qcommit
gitcan "create another release on-series without forcing" release create 1.0.6
shouldCoexist release/1.0.x release/1.0.6

wrapup
