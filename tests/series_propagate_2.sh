#!/bin/bash

# git-series - Copyright 2015 Justin Patterson - All Rights Reserved

. $(dirname $0)/common-propagate.sh

gitcant "cleanly propagate if there are conflicts" series propagate 0.1
( echo a && echo b && echo C && echo d && echo e && echo f ) > README
qgit add README
qgit commit -m "merge manually"

gitcan "finish propagating once conflicts are resolved" series propagate 0.1

qgit checkout series/0.1
readmeShouldBe a b C d e

qgit checkout series/0.2
readmeShouldBe a b C d e f
shouldDescendFrom series/0.1 series/0.2

qgit checkout series/0.3
readmeShouldBe a b C d e f
shouldDescendFrom series/0.1 series/0.3

qgit checkout develop
readmeShouldBe a b C d e f g
shouldDescendFrom series/0.1 develop

wrapup
