# fuse

This is an old version of libfuse initially released [here](https://github.com/LineageOS/android_external_fuse/tree/cm-14.1), which was patched with android support. It has been further patched for NDK cross compilation and Termux native compilation. The device kernel must support the fuse filesystem. Check "/proc/filesystems" for "fuse" entry. Linux kernels 2.6.14 or later
should contain FUSE support.

## Warning: unresolved security issue

Be aware that FUSE has an unresolved security bug
([bug #15](https://github.com/libfuse/libfuse/issues/15)): the
permission check for accessing a cached directory is only done once
when the directory entry is first loaded into the cache. Subsequent
accesses will re-use the results of the first check, even if the
directory permissions have since changed, and even if the subsequent
access is made by a different user.

This bug needs to be fixed in the Linux kernel and has been known
since 2006 but unfortunately no fix has been applied yet. If you
depend on correct permission handling for FUSE file systems, the only
workaround is to completely disable caching of directory
entries. Alternatively, the severity of the bug can be somewhat
reduced by not using the `allow_other` mount option.


## About

FUSE (Filesystem in Userspace) is an interface for userspace programs
to export a filesystem to the Linux kernel. The FUSE project consists
of two components: the *fuse* kernel module (maintained in the regular
kernel repositories) and the *libfuse* userspace library (maintained
in this repository). libfuse provides the reference implementation
for communicating with the FUSE kernel module.

A FUSE file system is typically implemented as a standalone
application that links with libfuse. libfuse provides functions to
mount the file system, unmount it, read requests from the kernel, and
send responses back. libfuse offers two APIs: a "high-level",
synchronous API, and a "low-level" asynchronous API. In both cases,
incoming requests from the kernel are passed to the main program using
callbacks. When using the high-level API, the callbacks may work with
file names and paths instead of inodes, and processing of a request
finishes when the callback function returns. When using the low-level
API, the callbacks must work with inodes and responses must be sent
explicitly using a separate set of API functions.


## Compile and Install Instructions for Linux Distros

It is best to go [here](https://github.com/libfuse/libfuse) for latest libfuse versions for pc distros and use those.
```
#install dependencies
sudo apt install autoconf automake libtool

cd fuse

#only if building from git repository to generate configure script
./makeconf.sh

#build
./configure
make -j8

#install if needed
make install
```

You may also need to add `/usr/local/lib` to `/etc/ld.so.conf` and/or
run *ldconfig*. If you're building from the git repository (instead of
using a release tarball), you also need to run `./makeconf.sh` to
create the `configure` script.

For more details see the file `INSTALL`


## Cross Compile Instructions for Android Using NDK

- Download [android_ndk_cross_compile_build_automator](https://github.com/agnostic-apollo/Android-NDK-Cross-Compile-Build-Automator) and read/follow its usage guide.

- Copy `fuse` directory to `android_ndk_cross_compile_build_automator/packages` directory.

- Copy `fuse/post_build_scripts/fusermount_extractor.sh` file to `android_ndk_cross_compile_build_automator/$POST_BUILD_SCRIPTS_DIR/` directory.

- Add/Set `fuse` to `$PROJECTS_TO_BUILD` in `android_ndk_cross_compile_build_automator.sh`.

- Add/Set `fusermount_extractor.sh` to `$POST_BUILD_SCRIPTS_TO_RUN` in `android_ndk_cross_compile_build_automator.sh`. You can skip this optionally if you do not want to create a zip of the fusermount binaries of all the archs that are built.

- Add/Set `armeabi armeabi-v7a arm64-v8a x86 x86-64` to `$ARCHS_SRC_TO_BUILD` in `android_ndk_cross_compile_build_automator.sh` or whatever ARCHS_SRC you want to build for. API_LEVEL in ARCH_SRC files must be 21 or higher otherwise compilation will fail. NDK must also be higher than r15. Check `fuse/android_ndk_cross_compile_build.sh` for more details.

```
#install dependencies
sudo apt install autoconf automake libtool

cd android_ndk_cross_compile_build_automator

#build
bash ./android_ndk_cross_compile_build_automator.sh

```

- `android_ndk_cross_compile_build_automator` will call `fuse/android_ndk_cross_compile_build.sh script` to build and install each ARCHS_SRC. fuse for each ARCHS_SRC will be installed at `android_ndk_cross_compile_build_automator/$INSTALL_DIR/fuse/$ARCHS_SRC`.

- `android_ndk_cross_compile_build_automator/$POST_BUILD_SCRIPTS_DIR/fusermount_extractor.sh` will extract `fusermount` binaries from `android_ndk_cross_compile_build_automator/$INSTALL_DIR/fuse/$ARCHS_SRC` and zip them at `android_ndk_cross_compile_build_automator/$OUT_DIR/fuse/fusermount<build-info>.zip`.


Fully static compile is not possible currently for fusermount binary using NDK since bionic libc does not support static linking (fully or at all), since binaries built for android are supposed to dynamically link with android system libraries of each phone and android version at runtime. Fusermount compiled with NDK will dynamically link with android system libc.so and/or libdl.so.
However the fusermount compiled with above flags is not linked with any termux libraries and should not need the export of termux lib path with LD_LIBRARY_PATH for execution. Fully static compile will probably be possible with mucl since its libc implementation has static support. A focus on only the fusermount binary is because it is required by [rclone](https://rclone.org) [mount](https://rclone.org/commands/rclone_mount) for mounting cloud drives like google drive in android with root of course. That was the motivation behind this all. 


## Install Instructions for Termux on Android

- Download release zip or copy the zip built from source to your device.

- Extract the binary of your device arch or abi from the zip.
```
#command to find device arch
uname -m

#command to find device abi
getprop ro.product.cpu.abi
```

- Copy the binary to `/data/data/com.termux/files/usr/bin` and then set correct ownership and permissions by running the following commands in a non-root shell. If you run them in a root shell, then binary will only be runnable in a root shell.
```
export scripts_path="/data/data/com.termux/files/usr/bin"; export termux_uid="$(id -u)"; export termux_gid="$(id -g)"; su -c chown $termux_uid:$termux_gid "$scripts_path/fusermount" && chmod 700 "$scripts_path/fusermount";
```


## Native Compile and Install Instructions for Android on Android Using Termux

```
#run following commands in a non-root shell

#install dependencies
pkg install build-essential git silversearcher-ag wget gettext

cd fuse

#must be run to generate configure script and fulfill dependencies in termux
./makeconf_termux.sh

#build
./configure CC=clang CXX=clang++ --enable-example=no --disable-mtab --enable-android=yes --enable-static=yes LDFLAGS="-static-libgcc"
make

#install fusermount by copying it to termux bin path and set correct ownership and permissions
cp ./util/fusermount /data/data/com.termux/files/usr/bin
export scripts_path="/data/data/com.termux/files/usr/bin"; export termux_uid="$(id -u)"; export termux_gid="$(id -g)"; su -c chown $termux_uid:$termux_gid "$scripts_path/fusermount" && chmod 700 "$scripts_path/fusermount";
```

Fully static compile is not possible currently for fusermount binary using termux since termux clang does not support static compilations and even if that were possible, fusermount would most likely still link dynamically with android system libc.so and/or libdl.so.
However the fusermount compiled with above flags is not linked with any termux libraries and should not need the export of termux lib path with LD_LIBRARY_PATH for execution.  

You can check out [Termux Build Packages Wiki](https://wiki.termux.com/wiki/Building_packages) for more helpful info.


## Security implications

If you run `make install`, the *fusermount* program is installed
set-user-id to root.  This is done to allow normal users to mount
their own filesystem implementations.

There must however be some limitations, in order to prevent Bad User from
doing nasty things.  Currently those limitations are:

  - The user can only mount on a mountpoint, for which it has write
    permission

  - The mountpoint is not a sticky directory which isn't owned by the
    user (like /tmp usually is)

  - No other user (including root) can access the contents of the
    mounted filesystem (though this can be relaxed by allowing the use
    of the `allow_other` and `allow_root` mount options in `fuse.conf`)


## Building your own filesystem

FUSE comes with several example file systems in the `examples`
directory. For example, the *fusexmp* example mirrors the contents of
the root directory under the mountpoint. Start from there and adapt
the code!

The documentation of the API functions and necessary callbacks is
mostly contained in the files `include/fuse.h` (for the high-level
API) and `include/fuse_lowlevel.h` (for the low-level API). An
autogenerated html version of the API is available in the `doc/html`
directory and at http://libfuse.github.io/doxygen.


## Getting Help

If you need help, please ask on the <fuse-devel@lists.sourceforge.net>
mailing list (subscribe at
https://lists.sourceforge.net/lists/listinfo/fuse-devel).

Please report any bugs on the GitHub issue tracker at
https://github.com/libfuse/main/issues.

