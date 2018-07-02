## 2018-07-02 - Release 2.2.1

### Summary

The module has been converted to Puppet PDK and has been tested on Ubuntu 18.04.

#### Features

- Add Ubuntu 18.04 (Bionic Beaver) to the list of supported operating systems.
- Convert to Puppet PDK.

## 2018-05-08 - Release 2.2.0

### Summary

This release adds the possibility to manage the seen flag for a debconf configuration item.

#### Features

- The type has a new `seen` parameter to define the value of the seen flag for an item. Setting this parameter to a boolean value will set the flag to the specified value. Leaving this parameter undefined will retain the old behavior.

## 2018-02-04 - Release 2.1.0

### Summary

This release removes support for some legacy OS releases and closes a bug.

#### Bugfixes

- Fix a bug where a pipe to a subprocess was closed too late. This caused a subprocess to become a zombie until the Puppet run finished.

## 2017-03-10 - Release 2.0.0

### Summary

This release no longer allows the `type` parameter to be empty when creating the resource. It also includes an important fix to correctly detect if a defined password needs to be updated.

#### Features

- Added Ubuntu 16.10 (Yakkety Yak) to the list of supported operating systems.

#### Bugfixes

- Added an additional validation for the `type` parameter. This effectively makes the parameter mandatory for `ensure => present`. The type of the entry is required when the entry is missing in the debconf database and has to be created.
- Fix a bug that prevented reading a preseeded password correctly. Previously a password item would trigger a resource update with every Puppet run.

## 2016-05-13 - Release 1.0.0

### Summary

Initial release.
