
* two styles
  * trusted - topic branches not needed, commits can be made directly to a series branch
  * pre-review - topic branchs are used to review code before merge to branch
  
* try to maintain semi-linear git histories
  * requires merging locally

* exists
  * series - explicit or implicit
  * release - explicit only
   
* minor branch
  * used for work targeted to the next release of a particular minor series.
  * it's ok if it ends up being in a different series
  
  
* cookbook
  * start a new project
    * create a branch names `series/X.Y` where `X` and `Y` are the major and
      minor version numbers of whatever you expect your first release to be.
      * this prevents you from creating topic branches off of this series as you must
        specify an _explicit_ series branch to create a topic. 
    * start working on any branch and it will assume that you're going to use
      `0.1` as your first minor release version.
    * if you want to use topic branches, create them using `git flux start-topic X.Y`
      to create a topic branch that branches off the most advanced commit in the `X.Y`
      series and will be merged back into that series when it is complete.
    * if you don't want to use topic branches, you can work off of and commit directly
      to the series branch.
  * release a new version
    * If you havae the code all ready to go on the series branch, all you have to do
      to create release is run `git flux mark-release X.Y`. This will tag the most
      advanced commit in the `series/X.Y` series with the nexy available release number.
      Determines the next available release number by seeing what other releases have 
      already been explicitly created.
      Open release v closed release.
      