# Manual for ebuild-test-suite
***

# About
This is a test suite for portage ebuilds in Gentoo!

An ebuild with several use flags can be time consuming to test - especially when the use flags trigger dependencies.
Then serious testing can require installing most or all possible combinations of use flags - to make sure that all dependencies are correct.

So this test suite should automate these tests.
The tests will still be time consuming, but one does not have to manually start each new installation.

So once an ebuild is considered ready for publication, I can start these test-scripts and look at the output hours later.

## Basic usage
The basic idea about using this test-suite is:
* Define packages to be tested, optionally restrict to specific versions
* The test-suite will then loop over all packages and available versions
* For each package-version, it will grab its USE flags and
* Loop over all possible combinations of USE flags, installing each combination

Defining packages (and versions) is a matter of creating a folder. That's it!  

* Optionally, the list of flags or flag combinations can be filtered.
* Optionally, post-installation tests for each package(-version) can be defined.

The optional parts follow a similar concept to Gentoos ebuilds. Simply implement specific functions if you want to use a feature.

## Other Features
* A test run can include several packages and/or versions
* Restart a test run where it was stopped.
* Customizable per package, even per version
* Uses binary packages when possible

***

# Installation
So far this test suite is just a set of scripts.  
Simply create a folder and checkout the git repository in there.

Then define your packages in the tests sub-folder.

_**Warning**_
_Use this **only** in virtual machines._
_This can do serious harm to your system, so test your ebuilds in virtual machines where no real harm can be done._

## Why use a VM for tests?
Several reasons, at least these:
* To test dependencies, the system should have a minimal installation.
* This script may break things.
* You should test several archs.

## Prerequisites:
* app-portage/eix : Needed to get information about packages
* app-portage/gentoolkit: For revdep-rebuild

***

# Definition Of Packages
The term "versions" in this document refers to the entire "version and revision" string ($PVR in ebuilds).

**Example package**  
Throughout this text, the package [app-text/peg-multimarkdown](https://github.com/Wuodan/local_overlay/tree/master/app-text/peg-multimarkdown) is used as example.  
It has 2 versions, "3.6" and "9999", with local ebuild files for each:  
* app-text/peg-multimarkdown-3.6.ebuild
* app-text/peg-multimarkdown-9999.ebuild

The 9999.ebuild has more use flags, features and also dependencies.  
  
The git repository contains my test configuration for this package in the "tests" folder.  
Taking a look at them might clarify things.  

## Defining packages (and versions)
The sub-folder **tests** contains the test definitions.

### Category/Package
Define a package by creating subfolders for the category and package.  
Example:  
`mkdir -p ./tests/app-text/peg-multimarkdown`  
This will include all version of the package in the test run.  

### Optional: Restrict to versions
If only certain versions shall be tested, define further sub-folders for each version.  
Example:  
`mkdir -p ./tests/app-text/peg-multimarkdown/9999`  
This will only include version 9999 and exclude all others versions of the package.

_Note:  
If the package-folder has no sub-folders, all versions are tested!  
All sub-folders are treated as versions, these versions must exist!_

## Run a simple installation test
This is enough to run simple installation tests.  
Started by:  
`./ebuild-test-suite.sh`  
it will loop over all defined package versions.  
For each version, it will loop over all possible combinations of use flags and install each combination.  
If anything goes wrong, it stops - can be restarted later.

Between each installation, "emerge --depclean" and "revdep-rebuild" are executed!
***

# Definition Of Package Specific Tests

## Files
The package (and optional version folder) may contain executable shell scripts.  
In there, specific functions for test-phases can be defined.

_Note:  
All scripts in a package-folder are included (source file) to load the functions.  
Then eventually existing scripts in the version-folder are loaded.  
Thus functions in version-specific scripts can override package-specific functions._

## Variables
The following variables will be available in the package/version scripts.
Not all variables will be available in all phases.
* ROOT: path to main script folder
* DIR_TEST: the "./test" folder
* DIR_CONF: the folder for generated config for restarts. ( Using it makes no sense usually.)
* CATPKG: "category/package" in one string ($CATEGORY/$PN in ebuilds)
* PVR: Package version and revision (if any), for example 6.3, 6.3-r1.
* FLAGS: List of all use-flags of a package-version (without "test" flag)
* FLAG_COMBINATIONS: List of all possible combinations of use-flags. One combination per line (line example: "doc -ssl latex")
* FILES: Currently list of files in some test-folder. This will be removed soon ...

_Note:  
These variables are protected.  
Overwriting them will not work unless where specified in the following section about functions!_  
=> Todo: Implement variable protection.

## Test-Phases and Functions

### Test-Phases
A test run is divided in these phases:
* **prepare**:  
Prepares the config for the test run. Loads package-versions, their use-flags and their possible combinations of use-flags. Nothing is installed at this phase.
* **init**:  
Initialize tests for an installed package-version. Example: wget some files to run tests with.  
Do not change the current execution path, this happens in a dedicated folder.
* **test**:  
Run tests on the installed package version. For example let the executable do something.

### Functions
Scripts in the package- (and optional version-) folder can contain these special functions:

**Phase prepare**:
* **pkg_flags()**:  
FLAGS is defined and can be manipulated.  
Use this to filter out flags prior to generation of possible combinations of flags. This can greatly reduce the number of tested combinations!
* **pkg_flag_combinations()**:  
FLAG_COMBINATIONS is defined and can be manipulated.  
Used to remove unwanted combinations or to append a combination if a flag was filtered out in pkg_flags().

**Phase init**:  
Execution path is a dedicated folder, do not cd anywhere!
* **pkg_init()**:  
Used to prepare tests for an installed package version.
Prior to each test, the folder is reset to how this function left it!  
_TODO: Improve this - without FILES variables ..._

**Phase test**:
* **pkg_test()**:  
Use flag independent test. If defined, this is called for all combinations of use flags.
* **pkg\_test\_$flag()**:  
For each flag that the current package version is installed with, a special function can be defined.
It is only called when the flag is active in the current combination of use flags.

**Example**:  
Use flags: `doc -latex shortcuts`  
Functions: `pkg_test() pkg_test_doc() pkg_test_latex()`  
=> pkg_test is always executed if defined.  
=> pkg_test_doc is executed because the "doc" flag is active.  
=> pkg_test_latex is not called because the "latex" flag is inactive.  
=> pkg_test_shortcuts is not defined and thus not executed.

***

# Tips
## Restarting
When a test is aborted, it can be restarted.  
Already tested packages, versions and use-flag combinations will be skipped.
## Pre-install packages
Example: The ebuild inherits the git-2.eclass. So git will be installed with every test-run.  
**Tip**: Manually emerge dev-vcs/git prior to running tests.  
Reason:  
Depcleaning the package and then depcleaning the system will also remove git, only to reinstall it with next test run.
## Binary packages
A full test run will install the same packages (from dependencies) over and over again.  
**Tip**: Let portage create binaries.  
Define PKGDIR and FEATURES="buildpkg" in make.conf  
_Hint: The test-suite uses `emerge --usepkg --binpkg-respect-use y`.  
Thus a binary will only be used if it was built with the same use flags._
## cchache
cchache is known to cause problems. So test without before you dig deep for other problems.  
But it can greatly speed up a test run, especially when not using binary packages.
## Virtual Machine
The point of testing dependencies is using a minimal system.  
But at least give the VM some power. I currently give them 6 of my 8 CPUs and 1GB RAM each.  
_Note: marduks [Virtual Appliance](https://bitbucket.org/marduk/virtual-appliance/wiki/Home) is what I use as template, at least the kernel.config_

***
# ToDo & Ideas
To do is a lot ;-) ... this project has just started!  
I would love feedback and/or ideas!  

* Better parsing of eix output: `scripts / get-pkg-version-info.sh` works, but is messy with regexp.
* Logging: No logging so far. If something goes wrong or a test fails, it just stops.
* Slots: Are ignored at the moment.
* Groups of packages: Currently, all tested packages are depcleaned before installing next version. Grouping packages is an idea to improve this.
* Ebuild for test-suite: no ebuild for this yet. Currently this is a lose set of shell scripts, depending on relative paths.
* Variable Protection: Think I know how ...
