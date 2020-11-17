# DependencyCheck
A simple ruby script to check if the pod describes all of it's dependencies on the podspec.

## Why is it important to check the dependencies?
When Xcode starts to compile a project, it first creates a dependency graph of the libs. This step is important because if one lib `A` depends on lib `B`, `B` should be compiled first. Otherwise, `A` would try to link its binary to `B`'s binary, but since it's not there yet, it fails to compile.

When a Pod omits a dependency in the podspec, Xcode fails to know this lib requires the dependency to be compiled first. So this relation is ommited from the dependency graph, making the build process up to luck.
