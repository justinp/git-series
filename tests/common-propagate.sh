. $(dirname $0)/common-test.sh

function readmeShouldBe {
  header=$( printf "%s:%-4d" $( caller | awk '{ print $2,$1 }' ) )
  compareOutput "$header" "README" "cat README" $@
}

function shouldDescendFrom {
  header=$( printf "%s:%-4d" $( caller | awk '{ print $2,$1 }' ) )
  _tgit "$header" -eq "$2 should descend from $1" rev-list $(git rev-parse $2^{commit}) \| tail +2 \| grep -x $(git rev-parse $1^{commit})
}

function shouldNotDescendFrom {
  header=$( printf "%s:%-4d" $( caller | awk '{ print $2,$1 }' ) )
  _tgit "$header" -ne "$2 should not descend from $1" rev-list $(git rev-parse $2^{commit}) \| tail +2 \| grep -x $(git rev-parse $1^{commit})
}

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

# Set up an interesting propgation scenario

qgit series create 0.1
qgit checkout series/0.1

( echo a && echo b && echo c && echo d && echo e ) > README
qgit add README
qgit commit -m "add README"

qgit release create 0.1.0

qgit series create 0.2

( echo a && echo b && echo C && echo d && echo e ) > README
qgit add README
qgit commit -m "capitalize c"

echo "HEY!" > LICENSE
qgit add LICENSE
qgit commit -m "add LICENSE"
qgit tag add_license

qgit checkout series/0.2

( echo a && echo b && echo d && echo e ) > README
qgit add README
qgit commit -m "remove c"

qgit series create 0.3
qgit checkout series/0.3

echo f >> README
qgit add README
qgit commit -m "add f"

qgit checkout -b develop series/0.3
echo g >> README
qgit add README
qgit commit -m "add g"
