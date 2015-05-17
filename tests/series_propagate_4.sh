#!/bin/bash

# git-series - Copyright 2015 Justin Patterson - All Rights Reserved

. $(dirname $0)/common-propagate.sh

gitcan "propagate, stopping at series 0.2" series propagate -d -n -t 0.2 0.1

qgit checkout series/0.1
readmeShouldBe a b C d e

qgit checkout series/0.2
readmeShouldBe a b d e
shouldDescendFrom series/0.1 series/0.2

qgit checkout series/0.3
readmeShouldBe a b d e f
shouldNotDescendFrom series/0.1 series/0.3

qgit checkout develop
readmeShouldBe a b d e f g
shouldNotDescendFrom series/0.1 develop

wrapup