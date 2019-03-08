## PIES

This repository contains code for the simulations in
[Torgovitsky, A.](https://a-torgovitsky.github.io/) (2019), ["Partial Identification by Extending Subdistributions."
_Quantitative Economics_, 10 (1), pp. 105–144, doi:10.3982/QE634](https://doi.org/10.3982/QE634)

### Important

The code included in the supplemental material for _Quantitative Economics_ is from April 9, 2018.  
Please download the most recent version of the code from the
[GitHub repository][GitHub].

### Software Requirements

* [MATLAB](https://www.mathworks.com/products/matlab.html).

  No special toolboxes are required.

* [A Mathematical Programming Language (AMPL)](http://ampl.com/).

 The student version of AMPL is size restricted.  
 Some simulations will probably run with the student version, but most will require a full license.

* A linear programming solver for AMPL.

 The default is [Gurobi](http://www.gurobi.com/).  
 It can easily be changed by passing e.g.  `Settings.LPSolver = 'cplex'`
 when calling `./src/IdentifiedSet.m`.  
 See the discussion on usage below.

* The [AMPL-MATLAB API](http://ampl.com/api/latest/matlab/getting-started.html).

* Linux (or perhaps OSX).

 I coded these simulations in Linux and made no attempt to be platform-independent.  
 However, the code is primarily in MATLAB, so should be mostly
 platform-independent.  
 Some file operations are used for recording the results of simulations.  
 These would be likely sources of issues for other operating systems, but should
 be easy enough to fix.

### Setup and Usage

* **Important first step**

 Open `./cfg/Config.m`. 

 Change `SAVEDIRECTORY` to a directory where you want simulations to be saved.

 Change `AMPLAPISETUPPATH` to the correct location for your installation of the
 AMPL-MATLAB API.

* The primary code is contained is `./src/IdentifiedSet.m` and the routines
  called from within.

 It contains many options that can be set, which are given default values in the
 structure called `Settings` that is defined at the top of that file.

 Another structure called `Assumptions` serves a similar purpose but only
 contains options that pertain to what assumptions are imposed when constructing
 the identified set.

* The directory `./run/` contains a file called `./Run.m` that can be used to
  run `IdentifiedSet.m` under limited pre-set options.

  For example, the command `Run(2,3,5)` would run specification number 2 from
  the paper with (d\_{1}, d\_{2}) = (3,5) in the notation there.

* Sequentially running all of the simulations in the paper will take a long
  time.
 The process can be sped up by using the file `./run/MultiBatchRun.m`, which opens
 multiple MATLAB threads.
 (Unfortunately, the AMPL-MATLAB API is not easy to parallelize.)
 The command to reproduce the results in the paper is

 `MultiBatchRun(1:1:14, 'your-save-dir')`

 Note that this will open 14 MATLAB and AMPL instances at one time, which will strain a typical system.
 To open fewer threads, pass a smaller array of numbers in the first argument, wait a while, then pass the remaining ones, using the same directory name.

### My Software Versions

The numerical results in the published paper were run with

* MATLAB version 8.6.0.267246 (R2015b)
* AMPL version 20170711
* Gurobi version 7.5.0
* AMPL-MATLAB API version 1.2.2.

### Software Acknowledgment

The code uses the MATLAB function
[MergeBrackets.m](https://www.mathworks.com/matlabcentral/fileexchange/24254-interval-merging) written by Bruno Luong.  
A copy of this code is included in `./src/MergeBrackets.m`.

### Problems or Bugs?

Please use [GitHub] to open an issue and I will be happy to look into it.

[GitHub]: http://www.github.com/a-torgovitsky/pies
