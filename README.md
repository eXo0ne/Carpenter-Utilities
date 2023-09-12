<div align="center">
  <br />
  <br />
  <img src="https://user-images.githubusercontent.com/67706277/206261506-c860c526-2aa7-4b30-8bdc-9e0e5efc286a.png" style="height: 125px;" />
  <br />
  <br />
  <br />
</div>

# Settings
`VerboseOutput` - When set to true, this will output potentially useful debugging information. Does not suppress warnings.

`SlowInitTimeout` - After an `::Init()` process has been running for this many seconds, Carpenter will warn you that it is slowing down the project.

`IgnoredJobNames` - Case-sensitive names of job modules that will be ignored (not required) during the initialization phase.
<br />
<br />
<br />

# Structure
The specific file structure in Carpenter only has a few components that have a set location, such as the `jobs` folder and are detailed here.

Other modules such as libraries or utilities may be placed anywhere in the appropriate context, though a suggested folder structure for these is provided by default.

Third-party modules should be placed in the `external` folder for the respective context, as this will bypass the otherwise enforced style and linting checks.

## Settings (Disabling/Ignoring Jobs)
As of 1.2.0, Carpenter now supports the ability to completely ignore job modules by name via the new `Settings.lua` file. All name entries are case-sensitive, and any job module that is ignored will output a warning to remind you that said module is ignored.

## Jobs
A job is a ModuleScript that contains code intended for execution at the start of the game. This is the only type of ModuleScript that is immediately executed, all other modules are lazy-loaded. In order to designate a ModuleScript as a job, it simply needs to be located under the provided `jobs` folder for its respective context (`client`, `server`, or `shared`)

### Initialization
Job initialization has three stages: loading, `::Init()`, and `::Run()`. Loading occurs when the ModuleScript is first required, and follows Roblox default behavior for `require()` with error handling. Each stage is performed and completed on all jobs before continuing to the next one.

#### ::Init()
An `::Init()` function may be specified in a job. The purpose of this function is to execute any code necessary to set up the environment for the job to run properly. This function is called synchronously, so it is highly recommended to avoid any yielding code here, if possible.

#### ::Run()
A `::Run()` function may also be specified in a job, which is intended to be any remaining code that the job needs to execute. This stage is called asynchronously, and is appropriate for any yielding operations.

#### Priorities
A job may have a Priority key specified, which determines the order in which it goes through the `::Init()` and `::Run()` stages. A higher priority value means that the job will run sooner than those with lower priority values. Every job that does not specify a priority value defaults to priority 0. Jobs with equal priorities are initialized in an arbitrary order, relative to each other. Negative priority values can be used to ensure that a job will be initialized *after* all other jobs.

Example:
```lua
local MyJob = {
    Priority = 4,
}
```
```lua
local MyOtherJob = {}
```
```lua
local MyLastJob = {
    Priority = -2
}
```
In this scenario, the initialization order would be: `MyJob`, `MyOtherJob`, `MyLastJob`

## Module Access
Modules can require other modules either by making use of the `shared()` override, or by defining a variable for Carpenter. This function can take either a string of the module's name, a string of a partial or complete path to the module, or a direct object reference to a ModuleScript. Valid examples:
```lua
local AnimNation = shared("AnimNation")
```
```lua
local AnimNation = shared("animation/AnimNation")
```
```lua
local AnimNation = shared(script.Parent.AnimNation)
```
```lua
local require = require(game:GetService("ReplicatedStorage").Carpenter)

local AnimNation = require("AnimNation")
```
### Use the shortest paths
Partial path support is included to help differentiate between modules with the same name. If you request a module name or path that is associated with multiple modules, Carpenter will warn you and ask you to be more specific. However, Carpenter does not index all potential file paths by default, so it is recommended to use the shortest unique paths possible in order to conserve memory usage.
### Hoarcekat
Hoarcekat stories can work with both `shared()` or `require()`, but the framework must be initialized in them beforehand. This means that at some point before getting dependencies in the story, you must have this line somewhere:
```lua
require(game:GetService("ReplicatedStorage").Carpenter)
```
<br />
<br />

# Contributions
Any Sawhorse engineer can contribute to Carpenter. The following are a list of principles and requirements to follow in making these contributions.
## Design Principles
### 1. Lightweight
The source code for Carpenter should be kept as small as possible (without obfuscation). Code that does not contribute to the framework's functions (such as utility or library modules) should not be included in this repository. A separate repository will be maintained to store reusable modules.
### 2. Simple
Carpenter should be easy and quick to use. The overarching goal of the framework is to make code organization easier for us, so that we can get work done faster. Changes to the framework should not cause us to spend more time interfacing with it than necessary.
### 3. Useful
Any change made to the framework must constitute a meaningful change for everybody. This means that we don't push changes that are "personal preference" (unless it is also the group preference), or will not be beneficial to more than one person. This is both for the spirit of collaboration, and to avoid unintuitive behavior.

## Rules
### 1. No external dependencies
We should be fully independent with Carpenter. All source code must have been written by a Sawhorse employee. This avoids any chance of us running into bigs or issues from an external party, which are often harder and take longer to debug.
### 2. All complex code must be documented
While the interface should be easy to use, the source code may not always be as straightforward. Any time a change is suggested containing complex processes, it must also contain sufficient documentation through comments or an amendment to this file.
### 3. No circular dependency support
Circular dependencies are considered to be an irregular and unaccepted coding practice. Therefore, Carpenter will not support them.
### 4. Style and linting enforcement
This repository is currently set up to enforce a style automated by StyLua and linting by Selene. All pull requests must pass these checks before they are merged. This helps keep code clean and consistent.

**NOTE:** The `external` folders in each context are exempt from these checks, and should only be used to store third-party code (not allowed in framework development, intended only for use in project scenarios).
