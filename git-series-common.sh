# git-series - Copyright 2015 Justin Patterson - All Rights Reserved

set -o pipefail

function exitScript {
  if [ "$0" != "-bash" ]; then
    exit 1
  fi
}

function prog_err {
  echo "fail: $1" >&2
  exitScript
}

function fatal {
  echo "fatal: $1" >&2
}

function error {
  echo "error: $1" >&2
}

function die {
  fatal "$1"
  exitScript
}

## Is the argument the correct format for a particular type?

function isSeriesFormat {
  [[ $1 =~ ^[0-9]+\.[0-9]+$ ]]
}

#function isSeriesRefFormat {
#  [[ $1 =~ ^series/[0-9]+\.[0-9]+$ ]]
#}

function isReleaseFormat {
  [[ $1 =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
}

#function isReleaseRefFormat {
#  [[ $1 =~ ^release/[0-9]+\.[0-9]+\.[0-9]+$ ]]
#}
#
## Dies if the argument is not in a specific format

function validateSeriesFormat {
  if ! $( isSeriesFormat $1 ); then
    die "invalid series format: $1"
  fi
}

function seriesExists {
  listSeries | grep -x $1 > /dev/null
}

function validateSeriesExists {
  if ! $( seriesExists $1 ); then
    die "series $1 does not exist"
  fi
}

function validateSeriesDoesNotExist {
  if $( seriesExists $1 ); then
    die "series $1 already exists"
  fi
}

#function validateSeriesRefFormat {
#  if ! $( isSeriesRef $1 ); then
#    die "unsupported series ref format: $1"
#  fi
#}

function validateReleaseFormat {
  if ! $( isReleaseFormat $1 ); then
    die "invalid release format: $1"
  fi
}

function releaseExists {
  listReleases | grep -x $1 > /dev/null
}

function validateReleaseExists {
  if ! $( releaseExists $1 ); then
    die "release $1 does not exist"
  fi
}

function validateReleaseDoesNotExist {
  if $( releaseExists $1 ); then
    die "release $1 already exists"
  fi
}


#function validateReleaseRefFormat {
#  if ! $( isReleaseRef $1 ); then
#    die "unsupported release ref format: $1"
#  fi
#}
#
## List all series in the repository, including remotes.

function listSeries {
  git for-each-ref --format "%(refname)" | while read ref; do
    if [[ $ref =~ ^refs/heads/series/([0-9]+\.[0-9]+)$ ]]; then
      echo ${BASH_REMATCH[1]}
    elif [[ $ref =~ ^refs/remotes/([^/]+)/series/([0-9]+\.[0-9])+$ ]]; then
      echo ${BASH_REMATCH[2]}
    fi
  done | sort -u
}

## List all release in the repository.
#
#function listReleaseRefs {
#  git for-each-ref --format "%(refname)" | while read ref; do
#    if [[ $ref =~ ^refs/tags/(release/[0-9]+\.[0-9]+\.[0-9]+)$ ]]; then
#      echo ${BASH_REMATCH[1]}
#    fi
#  done | sort -u
#}
#

# List all release in the repository.

function listReleases {
  git for-each-ref --format "%(refname)" | while read ref; do
    if [[ $ref =~ ^refs/tags/release/([0-9]+\.[0-9]+\.[0-9]+)$ ]]; then
      echo ${BASH_REMATCH[1]}
    fi
  done | sort -u
}

## This one includes series whose refs don't exist but which are implied by the existence of releases.

function listImpliedSeries {
  ( listSeries && listReleases | awk -F. '{ print $1"."$2 }' ) | sort -u
}

### Convert series refs into series versions.
##
##function listSeriesVersions {
##  while read ref; do
##    validateSeriesRefFormat $ref
##    echo $1 | sed -e s,series/,,
##  done
##}
#
#function listSeriesVersions {
#  listSeriesRefs | sed -e s,series/,,
#}
#
##function listImpliedSeriesVersions {
##}
#
## Does the specified series exist?
#
#
#function seriesVersionExists {
#  validateSeriesFormat $1
#  listSeriesVersions | contains $1
#}
#
#function seriesRefExists {
#  listSeriesRefs | contains $1
#}
#
## boolean - returns true even if the series branch is not there but there are releases that indicate it once existed
#function seriesExistsOrIsImplied {
#  seriesExists $1 || [ $( listReleasesForSeries $1 | wc -l ) -gt 0 ]
#}
#
## boolean
#function releaseExists {
#  listReleases | grep -x $1 > /dev/null
#}
#
#
#

#function listReleasesForSeries {
#  # TODO: validate $1?
#  listReleases | grep "^$1"
#}

function nextRelease {
  if [[ $1 =~ ^([0-9]+\.[0-9]+)\.([0-9]+)$ ]]; then
    echo ${BASH_REMATCH[1]}"."$(( ${BASH_REMATCH[2]} + 1 ))
  else
    prog_err "unexpected version: $1"
  fi
}

function takeUntil {
  awk '
    found != "y" { print }
    $0 == "'$1'" { found="y" }
  '
  # bash impl
#  print=y
#  while read item; do
#    if [ "$item" == "$1" ]; then print=n; fi
#    if [ "$print" == "y" ]; then echo $item; fi
#  done
}

function dropUntil {
  awk '
    found == "y" { print }
    $0 == "'$1'" { found="y" }
  '
  # bash impl
#  print=n
#  while read item; do
#    if [ "$print" == "y" ]; then echo $item; fi
#    if [ "$item" == "$1" ]; then print=y; fi
#  done
}
#
#function releasesBefore {
#  # TODO: validate
#  ( echo $1 && listReleases ) | sortReleasesPipe | uniq | takeUntil $1
#}
#
#function releasesAfter {
#  # TODO: validate
#  ( echo $1 && listReleases ) | sortReleasesPipe | uniq | dropUntil $1
#}
#
#function seriesBefore {
#  # TODO: validate
#  ( echo $1 && listSeries ) | sortSeriesPipe | uniq | takeUntil $1
#}
#

function seriesAfter {
  # TODO: validate
  ( echo $1 && listSeries ) | sortVersions | uniq | dropUntil $1
}

function lastReleaseForSeries {
  listReleases | filterSeries $1 | sortVersions | tail -1
}

function nextAvailableReleaseForSeries {
  last=$( lastReleaseForSeries $1 )
  if [ $? -eq 0 ]; then
    nextRelease $last
  else
    echo $1.0
  fi
}

#
#function makeSeriesSortablePipe {
#  while read v; do
#    if [[ $v =~ ^([0-9]+)\.([0-9]+)$ ]]; then
#      printf "%10d %10d\n" ${BASH_REMATCH[1]} ${BASH_REMATCH[2]}
#    else
#      die "unexpected series format: $v"
#    fi
#  done
#}
#
#function unmakeSeriesSortablePipe {
#  while read sv; do
#    if [[ $sv =~ ^\ *([0-9]+)\ +([0-9]+)$ ]]; then
#      echo ${BASH_REMATCH[1]}.${BASH_REMATCH[2]}
#    else
#      die "unexpected series format: $sv"
#    fi
#  done
#}
#
#function makeReleasesSortablePipe {
#  while read v; do
#    if [[ $v =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]; then
#      printf "%10d %10d %10d\n" ${BASH_REMATCH[1]} ${BASH_REMATCH[2]} ${BASH_REMATCH[3]}
#    else
#      die "unexpected release format: $v"
#    fi
#  done
#}
#
#function unmakeReleasesSortablePipe {
#  while read sv; do
#    if [[ $sv =~ ^\ *([0-9]+)\ +([0-9]+)\ +([0-9]+)$ ]]; then
#      echo ${BASH_REMATCH[1]}.${BASH_REMATCH[2]}.${BASH_REMATCH[3]}
#    else
#      die "unexpected release format: $sv"
#    fi
#  done
#}
#
#function sortReleasesPipe {
#  #  sort --key 1,10 -k 12,21 -k 23,32 - is this necessary?
#  makeReleasesSortablePipe | sort | unmakeReleasesSortablePipe
#}
#
#function reverseSortVersionsPipe {
#  #  sort --key 1,10 -k 12,21 -k 23,32 - is this necessary?
#  makeReleasesSortablePipe | sort -r | unmakeReleasesSortablePipe
#}
#
#function sortSeriesPipe {
#  makeSeriesSortablePipe | sort | unmakeSeriesSortablePipe
#}

function sortVersions {
  while read v; do
    if [[ $v =~ ^([0-9]+)\.([0-9]+)$ ]]; then
      printf "%10d %10d x\n" ${BASH_REMATCH[1]} ${BASH_REMATCH[2]}
    elif [[ $v =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]; then
      printf "%10d %10d %10d\n" ${BASH_REMATCH[1]} ${BASH_REMATCH[2]} ${BASH_REMATCH[3]}
    else
      die "unexpected format: $v"
    fi
  done | sort -n --key 1,10 -k 12,21 -k 23,32 | while read v; do
    if [[ $v =~ ^\ *([0-9]+)\ +([0-9]+)\ +x$ ]]; then
      echo ${BASH_REMATCH[1]}.${BASH_REMATCH[2]}
    elif [[ $v =~ ^\ *([0-9]+)\ +([0-9]+)\ +([0-9]+)$ ]]; then
      echo ${BASH_REMATCH[1]}.${BASH_REMATCH[2]}.${BASH_REMATCH[3]}
    else
      die "unexpected format: $v"
    fi
  done
}

#function priorReleaseForSeries {
#  # Add the new version into the list of existing versions, sort it and find the one that precedes the target version
#  release="$1.0"
#  ( echo $release && listReleases ) | sortReleasesPipe | grep -x -B 1 $release | head -1
#}
#
## boolean
#function seriesExists {
#  listSeries | grep -x $1 > /dev/null
#}
#
## boolean - returns true even if the series branch is not there but there are releases that indicate it once existed
#function seriesExistsOrIsImplied {
#  seriesExists $1 || [ $( listReleasesForSeries $1 | wc -l ) -gt 0 ]
#}
#
## boolean
#function releaseExists {
#  listReleases | grep -x $1 > /dev/null
#}

function seriesForRelease {
  [[ $1 =~ ^([0-9]+\.[0-9]+)\.([0-9]+)$ ]] && echo ${BASH_REMATCH[1]}
}

function canResolve {
  git rev-parse -q --verify $1 > /dev/null
}

function validateCommitExists {
  if ! $( canResolve $1 ); then
    die "commit $1 does not exist"
  fi
}

function resolve {
  git rev-parse $1^{commit}
}

function resolveVersion {
  if $( isReleaseFormat $1 ); then
    resolve release/$1
  else
    resolve series/$1
  fi
}

function contains {
  grep -x $1 > /dev/null
}

function isAncestor {
  git rev-list $(resolve $2) | tail +2 | contains $(resolve $1)
}

function isAncestorOrSelf {
  git rev-list $(resolve $2) | contains $(resolve $1)
}

#function isSeriesAncestorOfCommit {
#  release=$1
#  commit=$2
#
#  isCommitAncestorOfCommit $( resolve series/$release ) $commit
#}
#
#function isReleaseAncestorOfCommit {
#  release=$1
#  commit=$2
#
#  isCommitAncestorOfCommit $( resolve $release ) $commit
#}

function findPrior {
#  target=$1
  grep -x -B 1 $1 | grep -v -x $1
}

function findNext {
#  target=$1
  grep -x -A 1 $1 | grep -v -x $1
}

function filterSeries {
  egrep "^$1(\$|\.)"
}

function listRefsForSeries {
  ( listReleases && listSeries ) | filterSeries $1
}

## fail if release doesn't exist
#function priorRefSameSeries {
#  listRefsForSeries $(seriesForRelease $1) | sortVersions | findPrior $1
#}
#
## fail if release doesn't exist
#function nextRefSameSeries {
#  listRefsForSeries $(seriesForRelease $1) | sortVersions | findNext $1
#}

#function validate {
#  if [ -z "$2" ]; then
#    die "expecting something to validate and at least one thing to validate"
#  fi
#
#  item=$1
#  shift
#
#  type=$2
#  shift
#
#  case $type in
#    series_version)
#      if ! $(isSeriesVersion $item); then
#        die "unsupported series version: $item"
#      fi
#      while [ -n "$1" ]; do
#        case $1 in
#          exists)
#            seriesVersionExists $item
#            ;;
#          nonexistent)
#            ! $( seriesVersionExists $item )
#            ;;
#          *)
#            prog_err "unsupported $type validation option: $1"
#            ;;
#        esac
#        shift
#      done
#      ;;
#    series_ref)
#      if ! $(isSeriesRef $item); then
#        die "unsupported series ref: $item"
#      fi
#      while [ -n "$1" ]; do
#        case $1 in
#          exists)
#            seriesRefExists $item
#            ;;
#          nonexistent)
#            ! $( seriesRefExists $item )
#            ;;
#          *)
#            prog_err "unsupported $type validation option: $1"
#            ;;
#        esac
#        shift
#      done
#      ;;
#    release_version)
#      if ! $(isReleaseVersion $item); then
#        die "unsupported release version: $item"
#      fi
#      while [ -n "$1" ]; do
#        case $1 in
#          exists)
#            releaseVersionExists $item
#            ;;
#          nonexistent)
#            ! $( releaseVersionExists $item )
#            ;;
#          *)
#            prog_err "unsupported $type validation option: $1"
#            ;;
#        esac
#        shift
#      done
#      ;;
#    release_ref)
#      if ! $(isReleaseRef $item); then
#        die "unsupported release ref: $item"
#      fi
#      while [ -n "$1" ]; do
#        case $1 in
#          exists)
#            releaseRefExists $item
#            ;;
#          nonexistent)
#            ! $( releaseRefExists $item )
#            ;;
#          *)
#            prog_err "unsupported $type validation option: $1"
#            ;;
#        esac
#        shift
#      done
#      ;;
#
#    *)
#      die "unsupported validation type: $type"
#  esac
#
#}
#
#

function updateLastReleaseWildcardTag {
  # arg is series

  xtag=release/$series.x

  # Determine the commit where the xtag currently is (if it exists)

  oldLastCommit=$( canResolve $xtag && resolve $xtag )

  # Determine the release that the xtag should coexist with (if any)

  newLastVersion=$( lastReleaseForSeries $series )

  if [ -n "$newLastVersion" ]; then

    # Determine the commit where the xtag should be

    newLastCommit=$( resolve release/$newLastVersion )

    # If it's not where it should be, move it there.

    if [ "$oldLastCommit" != "$newLastCommit" ]; then
      git tag -f $xtag $newLastCommit
    fi

  elif [ -n "$oldLastCommit" ]; then

    # The xtag should not exist, but it does.  Delete it.

    git tag -d $xtag

  fi
}

function getReleaseDate {
  git cat-file -p $( git rev-parse release/$1 ) | grep ^tagger | sed -e 's,.*> ,,'
}


# Things for conversion from gitflow
#
#function isMergeCommit {
#  git rev-parse --verify $1^2 > /dev/null 2> /dev/null
#  [ $? -eq 0 ]
#}
#
#function listSegment {
#  # list all revs down to where the first merge is and then stop
#  git rev-list $1 | while read c; do
#    isMergeCommit $c
#    # merge commits will have a 0 in the first field, non-merge commits will have a 1
#    echo $? $c
#  done | awk '
#    $1 == 0 { stop="y" }
#    stop != "y" { print }
#  '
#}

#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#function rebuildSymbolicRefs {
#  # TODO: pull releases and series from remotes.  If they aren't here, bad things can happen.
#
#  listImpliedSeries | while read series; do
#    last=$( lastReleaseForSeries $series )
#    if [ -n "$last" ]; then
#      echo "$series.x -> $last"
#      git tag -f $series.x $last
#    fi
#  done
#
#  last=$( listSeries | sortSeriesPipe | tail -1 )
#  if [ -n "$last" ]; then
#    echo "next -> series/$last"
#    git symbolic-ref refs/heads/next refs/heads/series/$last
#  fi
#}
#
#
##=====================================================================================================================
## USAGES
##=====================================================================================================================
#
#function cmd_usage {
#  echo "usage: git flux <object>"
#  echo
#  echo "objects:"
#  echo "   stream    act on streams"
#  echo "   topic     act on topics"
#  echo "   release   act on releases"
#}
#
#function cmd_series_usage {
#  echo "usage: git flux series <action>"
#  echo
#  echo "actions:"
#  echo "   list      list existing series"
#  echo "   create    create a new series"
#  echo "   delete    delete an existing series"
#}
#
##=====================================================================================================================
## MAIN COMMAND DISPATCHER
##=====================================================================================================================
#
#noun=$1
#shift
#verb=$1
#shift
#
#case $noun in
#  series)
#    case $verb in
#      list)      cmd_series_list      "$@" ;;
#      create)    cmd_series_create    "$@" ;;
#      delete)    cmd_series_delete    "$@" ;;
#      rename)    cmd_series_rename    "$@" ;;
#      propagate) cmd_series_propagate "$@" ;;
#      *)         cmd_series_usage          ;;
#    esac
#    ;;
#
#  release)
#    case $verb in
#      list)   cmd_release_list   "$@" ;;
#      create) cmd_release_create "$@" ;;
#      delete) cmd_release_delete "$@" ;;
#      *)      cmd_release_usage       ;;
#    esac
#    ;;
#
#  admin)
#    case $verb in
#      rebuild) rebuildSymbolicRefs ;;
#    esac
#    ;;
#
#  *) cmd_usage ;;
#esac
#
##&& ! $( git merge-base --is-ancestor $last $branchpoint ) ]