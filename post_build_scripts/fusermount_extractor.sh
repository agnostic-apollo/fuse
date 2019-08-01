#!/bin/bash
#title:          fusermount_extractor.sh
#description:    Extracts fusermount binaries of all ARCH_SRCs, appended ARCH_SRC to each binary and then zips all the binaries
#author:         agnostic-apollo
#usage:          Copy `fuse/post_build_scripts/fusermount_extractor.sh` file to `android_ndk_cross_compile_build_automator/$POST_BUILD_SCRIPTS_DIR/` directory.
#                Add/Set `fusermount_extractor.sh` to `$POST_BUILD_SCRIPTS_TO_RUN` in `android_ndk_cross_compile_build_automator.sh`. 
#date:           1-Aug-2019
#versions:       1.0
#license:        MIT License


fuse_out_dir="$OUT_DIR/fuse"
build_info_file="$fuse_out_dir/build_info.txt"

build_timestamp="$(date +"%Y-%m-%d %H.%M.%S")"
build_info="Build Info:"
build_info+=$'\n'"NDK_FULL_VERSION=$NDK_FULL_VERSION"
build_info+=$'\n'"C_COMPILER=$C_COMPILER"
build_info+=$'\n'"HOST_TAG=$HOST_TAG"
build_info+=$'\n'"BUILD_TIMESTAMP=$build_timestamp"

if [ -d "$fuse_out_dir" ]; then
	rm -rf "$fuse_out_dir"
	if [ $? -ne 0 ]; then
	echo "Failed to remove $fuse_out_dir"
	exit 1
	fi
fi

mkdir -p "$fuse_out_dir"
if [ ! -d "$fuse_out_dir" ]; then
	echo "Failed to create $fuse_out_dir"
	exit 1
fi

fusermount_binary_found=0
for ARCH_FILE in "$ARCHS_DIR"/*; do

	ARCH_SRC="$(basename "$ARCH_FILE")"

	source "$ARCH_FILE"

	fusermount_binary_path="$INSTALL_DIR/fuse/$ARCH_SRC/usr/local/bin"
	if [ -f "$fusermount_binary_path/fusermount" ]; then
		fusermount_binary_found=1
		build_info+=$'\n\n\n\n'"ARCH_SRC=$ARCH_SRC"$'\n'"API_LEVEL=$API_LEVEL"
		build_info+=$'\n'"FUSERMOUNT=fusermount-$ARCH_SRC"
		build_info+=$'\n'"Binary Info:"$'\n'"$(cd "$fusermount_binary_path"; file fusermount)"
		build_info+=$'\n'"Shared Libraries:"$'\n'"$(readelf -d "$fusermount_binary_path/fusermount" | grep "NEEDED")"
		cp -fa "$fusermount_binary_path/fusermount" "$fuse_out_dir/fusermount-$ARCH_SRC"
	fi
done

if [ $fusermount_binary_found -eq 1 ]; then
	echo -e "\n\n"
	echo "$build_info"
	echo "$build_info" > "$build_info_file"
	fuse_out_zip="$OUT_DIR/fusermount-ndk-$NDK_FULL_VERSION-$C_COMPILER-$build_timestamp.zip"
	echo -e "\n\n"
	echo "Building fuse_out_zip at $fuse_out_zip"
	cd "$OUT_DIR"
	zip "$fuse_out_zip" "fuse"/*
	echo "Complete"
fi
