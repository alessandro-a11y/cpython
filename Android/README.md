# Python for Android

If you obtained this README as part of a release package, then the only
applicable sections are "Prerequisites", "Testing", and "Using in your own app".

If you obtained this README as part of the CPython source tree, then you can
also follow the other sections to compile Python for Android yourself.

However, most app developers should not need to do any of these things manually.
Instead, use one of the tools listed
[here](https://docs.python.org/3/using/android.html), which will provide a much
easier experience.


## Prerequisites

If you already have an Android SDK installed, export the `ANDROID_HOME`
environment variable to point at its location. Otherwise, here's how to install
it:

* Download the "Command line tools" from <https://developer.android.com/studio>.
* Create a directory `android-sdk/cmdline-tools`, and unzip the command line
  tools package into it.
* Rename `android-sdk/cmdline-tools/cmdline-tools` to
  `android-sdk/cmdline-tools/latest`.
* `export ANDROID_HOME=/path/to/android-sdk`

The `android.py` script will automatically use the SDK's `sdkmanager` to install
any packages it needs.

The script also requires the following commands to be on the `PATH`:

* `curl`
* `java` (or set the `JAVA_HOME` environment variable)


## Building

Python can be built for Android on any POSIX platform supported by the Android
development tools, which currently means Linux or macOS.

First we'll make a "build" Python (for your development machine), then use it to
help produce a "host" Python for Android. So make sure you have all the usual
tools and libraries needed to build Python for your development machine.

The easiest way to do a build is to use the `android.py` script. You can either
have it perform the entire build process from start to finish in one step, or
you can do it in discrete steps that mirror running `configure` and `make` for
each of the two builds of Python you end up producing.

The discrete steps for building via `android.py` are:

```sh
./android.py configure-build
./android.py make-build
./android.py configure-host HOST
./android.py make-host HOST
