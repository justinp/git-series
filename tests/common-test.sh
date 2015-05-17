TMP=/tmp/git-series-tmp-$$
REPO=/tmp/git-series-test-repo-00000

failures=0
tests=0

function compareOutput {
  header=$1
  label=$2
  cmd=$3
  shift 3

  rm -f $TMP
  touch $TMP
  for r in $@; do
    echo $r >> $TMP
  done

  msg="$label should be exactly $@"

  if [ $( eval $cmd | md5 ) == $( cat $TMP | md5 ) ]; then
    echo "$header = pass: $msg"
  else
    echo "$header = FAIL: $msg"
    echo "  Expected:"
    awk '{ print "    "$0 }' < $TMP
    echo "  Actual:"
    $cmd | awk '{ print "    "$0 }'
    failures=$(( failures + 1 ))
  fi

  tests=$(( tests + 1 ))
  rm $TMP
}

function releasesShouldBe {
  header=$( printf "%s:%-4d" $( caller | awk '{ print $2,$1 }' ) )
  compareOutput "$header" "releases" "git release list" $@
}

function seriesShouldBe {
  header=$( printf "%s:%-4d" $( caller | awk '{ print $2,$1 }' ) )
  compareOutput "$header" "series" "git series list" $@
}

function impliedSeriesShouldBe {
  header=$( printf "%s:%-4d" $( caller | awk '{ print $2,$1 }' ) )
  compareOutput "$header" "implied series" "git series list -a" $@
}

# Asserts that $1 and $2 exist at the same commit

function shouldCoexist {
  header=$( printf "%s:%-4d" $( caller | awk '{ print $2,$1 }' ) )

  c1=$( git rev-parse "$1^{commit}" )
  c2=$( git rev-parse "$2^{commit}" )

  if [ $c1 == $c2 ]; then
    echo "$header = pass: $1 == $2"
  else
    echo "$header = FAIL: $1 ($c1) != $2 ($c2)"
    failures=$(( failures + 1 ))
  fi

  tests=$(( tests + 1 ))
}

# internal - a quiet git call

function _qgit {
  git $@ > /dev/null 2> /dev/null
}

# internal - a git command that establishes a test case

function _tgit {
  header=$1
  op=$2
  msg=$3
  shift 3

  eval git "$@" > $TMP 2> $TMP
  if [ $? $op 0 ]; then
    echo "$header = pass: $msg"
    if [ -n "$VERBOSE" ]; then
      awk '{ print "    "$0 }' < $TMP
    fi
  else
    echo "$header = FAIL: $msg"
    awk '{ print "    "$0 }' < $TMP
    failures=$(( failures + 1 ))
  fi

  tests=$(( tests + 1 ))
  rm $TMP
}

# a test case where git is expected to succeed (return zero exit code)

function gitcan {
  msg="can $1"
  shift
  _tgit "$( printf "%s:%-4d" $( caller | awk '{ print $2,$1 }' ) )" -eq "$msg" "$@"
}

# a test case where git is expected to fail (return non-zero exit code)

function gitcant {
  msg="can't $1"
  shift
  _tgit "$( printf "%s:%-4d" $( caller | awk '{ print $2,$1 }' ) )" -ne "$msg" "$@"
}

commitNumber=0

# a git call that's expected to succeed (quietly)

function qgit {
  header=$( printf "%s:%-4d" $( caller | awk '{ print $2,$1 }' ) )

  git "$@" > $TMP 2> $TMP
  ec=$?
  if [ "$ec" -ne "0" ]; then
    echo "$header = FATAL: git command expected to succeed has failed" >&2
    echo "  " git $@
    awk '{ print "    "$0 }' < $TMP
    echo exitCode=$ec
    exit $ec
  fi
}

function qcommit {
  _qgit commit --allow-empty -m "c$commitNumber"
  commitNumber=$(( commitNumber +1 ))
}

function wrapup {
  if [ -z "$KEEP_REPOS" ]; then
    rm -rf $REPO
  fi
  echo "Results: run: $tests, failed: $failures"
  exit $failures
}

echo Running test suite: $(basename $0)
echo Using temporary git repository in $REPO

rm -rf $REPO
mkdir -p $REPO
cd $REPO
qgit init
qcommit
