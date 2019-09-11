# git-series

An intelligent way to manage multiple concurrently-deployed releases using
git.

## Motivation

I've used git-flow for a long time. It's great if you have a simple project
that always only has one version deployed. In my experience, it happens more
often than not that there are more than one version in production. Before
you say "well, you write crappy old-school software," allow me to say that
one of those situtations is multiple containerized microservices sharing 
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

It also assumes that you are going to generate your versions automatically
from the git metadata, as opposed to having a source file that you have to
commit to update the version.
 
A _release_ is a version of the software that you make available to others.
It is identified by three version numbers (e.g., `1.1.2`), as is typical 
in semantic versioning.

A sequence of releases that all share the same major and minor versions is 
a _series_. It is identified by its two version numbers (major and minor - 
e.g., `1.2`). Releases that share the same major and minor versions with a 
series are _members_ of that series. So, the releases `1.1.1` and `1.1.2` 
are both members of the series `1.1`. Releases that are members of the same
series are also called _sibling_ releases.

There is nothing about major releases that is special to `git-series`. The
series `2.1` and the series `3.0` are just as related as the series `2.1`
and the series `2.2`, which is not much at all.
 
An _open_ release is one that you can still add commits to. It represents
ongoing work that is leading to the actual delivery of your software. A 
_closed_ release is one that you can no longer add commits to because it 
has been delivered. A series is always open. It can always receive new 
commits. It can not be closed. Generally, you can think of open releases 
and series (which must always be open) as representing the future and 
closed releases as representing the past.

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
decisions you made when the changes were fresh in your mind.

A _topic_ represents some work in progress. A topic can be opened 
against either a series or a release, which indicates where the
commits are to be added. Once the work is completed, the topic is closed.
Topics should be opened against the first release or series in the 
succession that will need the changes because `git-series` provides tools 
to help you propagate those changes to its successors. It provides no 
tools to backport changes to its predecessors. 

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

Note: `git-series` needs all of the tags and branches to exist locally
for it to correctly validate them against the `git-series` schema. When
you fetch commits from the remote, make sure to specify `--tags` or set
up the remote to automatically fetch tags by configuring 
`remote.<name>.tagOpt`. (See the `git-config` man page for more details.)


### Series

A `git-series` series is represented by a `git` branch whose name is in the
format `series/X.Y` where:
 * `X` is the major version
 * `Y` is the minor version 

Series branches are where most of your topic branches will be based.
Therefore, they are where most of your work will be merged when it is 
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

It is a consistency error to have both a release tag and a release
branch for the same release. The `git-series` tools won't allow you
to do this, but you can get into this situation if you manipulate the
refs directly through `git`.

The implication is that, while a release is open, it can accept more
commits. Once it is closed, it's a bit of historical information. It 
represents what you delivered to consumers at some point in the past.
You can't change history. Once a release tag is created in `git`, it
should not be moved or deleted.


### Wildcard Releases

> Note: I think there may not really be a reason to have this. It won't
> produce an artifact that can be used to track the most stable release.
> That needs to happen on the consumer side somehow. Why would you want
> to check out the code from the most recent release of a series? Either
> you know what release you're looking for, or you're looking to add
> code and you should be using the series (or a specific release branch).

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

> Note: There's arguably not a reason to have this. You can always
> just create a `series/1.0` (or whatever) and use that. still, some 
> developers may want it since it saves them from having to think at
> all.

In `git-series` the `develop` branch represents future work that is not yet
targeted to a specific series. Practically, `develop` is just an unnamed
series branch. When `git-series` needs a series name for the `develop`
branch (e.g., when generating artifact version numbers), it just increments
the minor version of the most-advanced highest explicitly-opened series.

You may choose to operate without a `develop` branch, especially if you
want to manually control the naming of artifacts on the bleeding edge.


### Semantic Version Inference

Given the git metadata of a particular commit, tools can generate a
unique, semantic version for the artifacts using the following rules
in order from highest precedence to lowest:

 * If the current branch matches the pattern `series/X.Y` then the
   semantic version is `X.Y-SNAPSHOT`.
 * If the current branch matches the pattern `topic/X.Y/name` then the
   semantic version is `X.Y-name-SNAPSHOT`.
 * If the current branch matches the pattern `release/X.Y.Z` then the
   semantic version is `X.Y.Z-SNAPSHOT`.
 * If there's a tag at `HEAD` that matches the pattern `release/X.Y.Z`
   then the semantic version is `X.Y.Z`.

where:
 * the current branch is determined using `git rev-parse --abbrev-ref HEAD`
 * tags at `HEAD` are determined using `git tag --points-at HEAD`


### Invariants

This is a list of invariants that must hold true in the git metadata
for the history to be consistent with respect to `git-series`.

#### Sibling Ancestry

_Each closed release tag descends from every closed, sibling release tag 
that it succeeds._

This deals only within the realm of `git-series` past (for all closed,
release tags). It means that `7.11.2` descends from `7.11.1` 
and `7.11.0` (assuming all these releases exist and are closed). Since 
descent is transitive, the last assertion above (that `7.11.2` descends 
from `7.11.0`) is implied by the fact that `7.11.2` descends from 
`7.11.1` and that `7.11.1` descends from `7.11.0`.
  
It is a little weird to talk about siblings descending from each other,
but remember that they are siblings only with respect to `git-series` 
(they are both members of the same series). As far as the `git` commits 
themselves are concerned, one of these releases is a descendant of the 
other.

One practical implication of this is that, if you close `release/3.0.2`
_before_ you close `release/3.0.1`, you _can not_ close `release/3.0.1`
after adding another commit. It would be impossible to go back and modify
`release/3.0.2` to descend from the new commit. You still have options.
You could either close `release/3.0.1` as a commit that `release/3.0.2`
already descended from. You could also rename it and release it as 
`release/3.0.4`.


#### Series Ancestry

_Each open release or series branch descends from every release and 
series it succeeds._

This is central to the `git-series` philosophy. It means that
`series/2.1` descends from `series/2.0`, `series/1.7`, `series/1.0`, 
`series/0.1`, closed `release/2.1.0`, open `release/2.1.1`, and potentially
every other series or branch that is succeeds. It says nothing about its
relation with its predecessor series.

Realize that this does not imply that the change must be incorporated into 
all future releases, just that you must make a decision and record it
within the `git` metadata. Propagation the process of maintaining this
invariant. For more details, see the [_Propagation_](#Propagation) section.

> Note: These is not _really_ an invariant. It's an "eventually consistent."
> During some operations or when you haven't propagated for a while, it's 
> possible that this statement will not hold true. The goal is to minimize 
> the amount of time during which it's not true. 


### Propagation

Propagation is the process by which you maintain the _Series Ancestry_ 
invariant. This concept is central to `git-series` because, any time you 
make a change to a version, you need to decide whether or not that change
(or a corresponding change) needs to be made to each open successor. The 
moment you author a change is the best time to consider its impact
on all future releases, so it's best to record your decision then.

Changes have no impact on closed successors. As mentioned before, once a 
release is closed it can not be modified. This may be a little confusing
at first because the word "successor" in natural language implies that 
it is something that comes later in time. Here, we're referring to the 
succession of releases which is a semantic ordering. It should seem 
reasonable that you could close `release/1.0.102` (a patch to an older 
series) _after_ you've closed `release/2.0.0` (the first release of a 
newer series), and yet in our terminology, the latter is a successor of 
the former.

It's important to realize that `git` determines whether or not a commit
needs to be merged into a branch solely based on whether that commit is
an ancestor of the branch or not. It doesn't take the contents of the 
files at that commit into account at all. Once `git` decides that it 
needs to create a merge commit (because the commit being merged is not
an ancestor of the branch into which you're merging it), the contents
of the files _does_ matter.

As an example, merging two branches which both have the same tree will 
result in a merge commit with the same tree as both its parents. The 
only thing different among the three branches will be the metadata 
associated with the tree. If you attempt to merge in the same direction
again, `git` will tell you that the branch is up-to-date. That's not
because the content is already the same, but because the target branch
moved to the merge commit during the first merge. When you request the
merge again, `git` sees that the source branch is an ancestor of the
target branch and knows that there's nothing further to do.

To prove this, you can create two branches (say `master` and `other`)
with different content and merge `other` to `master` using the `ours`
strategy (`git co master && git merge -s ours other`). Using this
merge strategy means that you want the resulting commit (which will 
soon be the new head of the `master` branch) to contain the same tree 
as the current `master` branch. Specifying this strategy on the
command line will prevent `git` from pausing so that you can 
interactively resolve the conflicts. You've already told it how you 
want any conflicts resolved. This merge will create a new merge 
commit that has the same tree as the parent from the `master` branch
(e.g., `git diff master master^1`), but a different tree than the 
parent from the `other` branch (e.g., `git diff master master^2`).
Nevertheless, when you request the same merge again, even
without the merge strategy specified, `git` will tell you that `master`
is up-to-date. This has nothing to do with the similarity of the trees.
`git` just knows that when you were asked what changes from `other`
needed to be incorporated into the `master` branch, your answer was
"none" and `git` remembers this through its metadata.
If you make further commits on the `other` branch, you will again need
to tell `git` how that change should be carried over to the `master`
branch.  

You can see how `git` enables `git-series` to keep track
of what decisions you make concerning the propagation of changes from
preceding versions into successive versions. `git-series` just provides
you with a strategy and tools to make sure that you don't miss any of
the merges that you should consider.

Any time you add a commit to a `git-series` branch, you should 
propagate those changes forward to all successive `git-series` branches.
In essence, this really means that you must merge it to the next branch
in the succession. Since that adds a commit to the next branch, now 
you must merge _that_ change to _its_ successor, and so on. This is one
reason why having many open branches (working on a bunch of
different versions concurrently) is not recommended. `git-series` can
help you manage that complexity, though.

Practically, it often doesn't make sense to attempt to propagate each
commit fully every time you make a change. `git-series` allows this 
sort of laxity by only checking the invariants when you're about to 
close a release. (You can also ask it to check and produce a report 
at any time.) You'll have to find the right balance between generating
a bunch of propagation work each time you commit and taking a chance 
with forgetting the context if you wait too long to propagate a batch 
of commits. 


### Explicitness

An _explicit_ series is one that has an existing branch in your 
repository. An _implicit_ series is one that is implied by the presence
of releases but which may not actually exist. For example, having a
release (open or closed) named `release/2.3.1` implies the existence
of a `2.3` series.

This situation can occur because you've decided you will never make
another release in this series and have deleted its branch. This may
make it easier to look at a series list without having older series
confuse things. If you decide that you want to (or must) release a
new version of that series, you can always recreate the series branch
as long as the invariants hold.

A release can never be implied. The presence of a `2.4.3` release
_does not_ imply the existence of a `2.4.2` release or a `2.3.0`
release or a `1.0.0` release.

Explicitness is similar to (but unlike) the open/closed distinction 
for releases. In both cases, an implicit series or a closed release,
you can no longer add commits. The difference is that you can decide
to make a series explicit again and then add commits to it. You can
never reopen a closed release once it is closed.  

Whether a series is implicit or explicit, it is said to _exist_.
