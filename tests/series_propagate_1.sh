#!/bin/bash

# git-series - Copyright 2015 Justin Patterson - All Rights Reserved

. $(dirname $0)/common-propagate.sh

# Check preconditions that should be in place after common-propagation.sh runs

shouldNotDescendFrom series/0.1 series/0.2
shouldNotDescendFrom series/0.1 series/0.3
shouldNotDescendFrom series/0.1 develop

# Check unhappy commands

gitcant "propagate form an invalid series" series propagate blurf
gitcant "propagate form a nonexistent series" series propagate 1.0
gitcant "propagate through an invalid series" series propagate -t blurf 0.1
gitcant "propagate through a nonexistent series" series propagate -t 1.0 0.1
gitcant "propagate from a nonexistent commit" series propagate -c m1 0.1
gitcant "propagate from a commit not not on the series" series propagate -c develop 0.1

# Check the first propagation scenario

gitcan "propagate, ignoring conflicts in favor of their version" series propagate -n 0.1

qgit checkout series/0.1
readmeShouldBe a b C d e

qgit checkout series/0.2
readmeShouldBe a b d e
shouldDescendFrom series/0.1 series/0.2

qgit checkout series/0.3
readmeShouldBe a b d e f
shouldDescendFrom series/0.1 series/0.3

qgit checkout develop
readmeShouldBe a b d e f g
shouldDescendFrom series/0.1 develop

wrapup