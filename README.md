# git-series

An intelligent way to manage multiple concurrently deployed releases in git.

## Motivation

I've used git-flow for a long time. It's great if you have a simple project
that always only has one version deployed. In my experience, it happens more
often than not that there are more than one version in production. Before
you say "well, you write crappy old-school software," allow me to say that
one of those situtation is multiple containerized microservices sharing 
a common library. Since these microservices are isolated from each 
other, they can choose to use whatever version of the library they desire.
It's possible (maybe even likely) that the team maintaining one of those
services won't want to upgrade to the latest, greatest version of the library
in lock step with the rest of the teams. So, what happens when they find a
bug in the old version of the library they were using? A hotfix is in order.
If you strictly use git-flow, `master` becomes a little confusing. Now, your
old-release hotfix is the most recently released version of the library,
but it's not the latest and greatest.

So, how do you manage to maintain a repository that makes it clear what 
versions have been released and when? How do you know which one to use if 
you want the latest and greatest? How do you clearly prescribe a process 
for fixing bugs in former releases and propagating those changes to the 
newer versions that need them?

Enter `git-series`!

## Concepts

`git-series` assumes that you're using [semantic versioning](https://semver.org/)
for your artifacts.

A _release_ is a version of the software that you make available to others.
It is identified by three version numbers (e.g., `1.1.2`), as is typical 
in semantic versioning.

A sequence of releases that all share the same major and minor versions is 
a _series_. It is identified by its two version numbers (major and minor - 
e.g., `1.2`). Releases that share the same major and minor versions with a 
series are _members_ of that series. So, the releases `1.1.1` and `1.1.2` 
are both members of the series `1.1`.

There is nothing about major releases that is special to `git-series`. The
series `2.1` and the series `3.0` are just as related as the series `2.1`
and the series `2.2`, which is not at all.
 
An _open_ release is one that you can still add commits to. It represents
ongoing work that is leading to the actual delivery of your software. A 
_closed_ release is one that you can no longer add commits to because it 
has been delivered. A series is always open. It can always receive new 
commits. It can not be closed.

All of the releases and series in your repository can be put into an 
overall succession. A _successor_ is any version that logically follows 
another. For any two releases that are members of the same series the
release with the [higher precedence](https://semver.org/#spec-item-11)
is the successor. The series itself succeeds all of its member releases
because it represents the possibility of another member release with a 
higher patch number than all of its existing member releases. Lastly,
a series is succeeded by any releases from other series with a higher
precedence. Here is a sample succession:

`1.0.0` < `1.0.1` < `1.0.2` < `1.0` < `1.1.0` < `1.1` < `1.2.0` < `1.2` < `2.0.0` < `2.0` < `2.1.0` < `2.1` < `3.0`
 
The successor relationship is important because it helps you to think about 
and organize the forward-propagation of changes made to your software. When 
any change is made, you must consider which open successors also need those 
changes. The tools that `git-series` provides make it easy either to 
propagate those changes to its successors or mark them as not needing 
propagation so that future maintainers will have a clear idea of the
decisions you made.

A _topic_ represents some work in progress. A topic can be opened 
against either a series or a release, which indicates where the
commits are to be added. Once the work is completed, the topic is closed.
Topics should be opened against the first release or series in the 
succession that will need the changes because `git-series` provides tools 
to help you propagate those changes to its successors. It provides no 
tools to backport changes to versions earlier in the succession. 

You may ask, "What if the consumer is on version `1.1.1` and finds a bug,
but we've already released `1.1.7`? Can we release a patch on `1.1.1`?
Maybe `1.1.1.1`?" The answer is "no." If you're following semantic 
versioning, there should be nothing from `1.1.2`-`1.1.7` that should break 
the consumer's code. You should be able to put the fix into `1.1.8` and 
have them upgrade to that release. In terms of `git-series`, this is 
creating the next new release within the series `1.1` and releasing it.

## Schema

The "schema" is just a set of `git` metadata patterns used to realize the 
concepts above. By following these patterns, no extra information needs to
be stored outside of the `.git` directory. `git-series` provides a set of
tools that help you to follow this schema. You could always decide to 
follow the patterns without actually using the tools. That's up to you.


### Series

A `git-series` series is represented by a `git`branch whose name is in the
format `series/X.Y` where:
 * `X` is the major version
 * `Y` is the minor version 

Series branches are where most of your topic branches will be based.
Hence, they are where most of your work will be merged when it is 
completed and/or approved. A series branch is similar to the `develop` 
branch in the `git-flow` model except that, instead of there being a 
single place in the repository for development work, there is one per 
series.


### Releases

A `git-series` release is represented in one of two ways in `git`. While 
the release is open, it exists as a `git` branch which is rooted off the
series branch of which it is a member. Once the release is closed, it is
replaced with a `git` annotated tag. Both of these `git` refs have a
name conforming to the format `release/X.Y.Z` where, unsurprisingly:
 * `X` is the major version
 * `Y` is the minor version 
 * `Z` is the patch version 

The implication is that, while a release is open, it can accept more
commits. Once it is closed, it's a bit of historical information. It 
represents what you delivered to consumers at some point in the past.
You can't change history. Once a release tag is created in `git`, it
should not be moved or deleted. 


### Wildcard Releases

A `git-series` _wildcard release_ is represented as a `git` lightweight 
tag whose name is in the format `release/X.Y.x` where:
 * `X` is the major version
 * `Y` is the minor version 
 * `x` is literally the character 'x'

A wildcard release points to the most recent release to have been 
closed in its series. It moves every time you modify a member release 
in the series. Unlike a release tag, this is not stable. It _will_
change as new releases are closed in the series.


### Develop

In `git-series` the `develop` branch represents future work that is not yet
targeted to a specific series. Practically, `develop` is just an unnamed
series branch. When `git-series` needs a series name for the `develop`
branch (e.g., when generating artifact version numbers), it just increments
the minor version of the highest explicitly-opened series.

You may choose to operate without a `develop` branch, especially if you
want to manually control the naming of artifacts on the bleeding edge.


## Workflow

As you begin to work on your repository, you can just use a `develop` branch.
If you have a PR-based process, it makes sense to create topics based on the
develop branch. 



A _release branch_ is a branch that is specifically created with a release in
mind. It can be used to isolate the work required to put the finishing touches 
on a given release without prohibiting other work in the series. A release branch
is not strictly required. If you do not have multiple threads of work going on 
concurrently within a series (this is often the case for an older series), you can
just create a release from the series branch. 




If you modify any of the metadata outside of the tools and break the pattern 
and then attempt to use the tools, they will likely fail. 

## Command Line Reference

### `git series`

```
usage: git series list [-a] [-v]
   or: git series convert
   or: git series create [-f] <new-series> [commit]
   or: git series rename [-f] <old-series> <new-series>
   or: git series delete [-f] <name>
   or: git series propagate [-d] [-n] [-c from-commit] [-t through-series] <from-series>
   or: git series check [-r]
```

#### list

Presents all of the series names in order from oldest to newest.

With `-a`, you'll also get the "next" series as inferred from the presence 
of a `develop` branch. If you have no `develop` branch, the output will 
be the same with or without `-a`.

_("-a" doesn't actually seem to work.)_

With `-v`, you'll also get some stats about each series, including the
number of releases in that series and the number of commits it has.

#### create

Creates a new series at the current `HEAD` commit or at the commit you
specify.

_(what does "-f" do? It doesn't let you move it.)_