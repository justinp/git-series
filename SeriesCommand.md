## `git series`

```
usage: git series list [-a] [-v]
   or: git series create <new-series> [commit]
   or: git series rename <old-series> <new-series>
   or: git series delete [-f] <name>
   or: git series propagate [-d] [-n] [-c from-commit] [-t through-series] <from-series>
   or: git series check [-r]
```

### list

Presents all of the series in order of succession.

With `-a`, you'll get a list of all existing series as well as any 
implied series. If you have a `develop` branch and you use the `-a`
flag, the last series in the succession will be the one that's implied
by the presence of a `develop` branch.

With `-v`, you'll also get some stats about each series, including the
number of releases in that series and the number of commits it has.

### create

Creates a new series at the current `HEAD` commit or at the commit you
specify.

> What does "-f" do? It doesn't let you move it!

### rename

Renames a series. This is something you may want to do if you, for
example, started with `series/0.1` and decided to go ahead and mark
your first release as `release/1.0.0`. You would need to rename
`series/0.1` to `series/1.0` before creating the release.

This is not allowed if you have closed member releases in the series.
In that case, you will need to just create the new series and begin
working there.  
