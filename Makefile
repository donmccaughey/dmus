TMP ?= $(abspath tmp)

IOS_CHECK_DEVICE ?= iPhone 16e

app_files = $(shell find dmus -type f -not -name '.*')
arch = $(shell uname -m)
package_files = $(shell find dmusBase -type f -not -name '.*')
product = MC Mus
project_files = dmus.xcodeproj/project.pbxproj
release_dir = $(TMP)/Release
app = $(release_dir)/$(product).app
src_files = \
		 .git/hooks/pre-commit \
		$(app_files) \
		$(package_files) \
		$(project_files)
ver = 1.0


.SECONDEXPANSION :


# ----- phony targets -----


.PHONY : check
check : $(TMP)/checked-iOS.stamp $(TMP)/checked-macOS.stamp


.PHONY : release
release : $(TMP)/made-disk-image.stamp


.PHONY : list-simulators
list-simulators :
	xcodebuild -project dmus.xcodeproj -scheme dmus -showdestinations


.PHONY : clean
clean :
	rm -rf *.profraw
	rm -rf $(TMP)


# ----- file targets -----


.git/hooks/pre-commit : scripts/pre-commit
	cp $< $@


$(TMP)/ \
$(TMP)/Release :
	mkdir -p $@


# use a stamp file since the app bundle is a directory and thus doesn't have an
# `st_mtime` usable for change detection; also, the app bundle name contains a
# space and thus can't be a target name
$(TMP)/built-release.stamp : \
		$(TMP)/checked-iOS.stamp \
		$(TMP)/checked-macOS.stamp \
		| $(release_dir)
	rm -rf $(release_dir)
	xcodebuild build \
		-project dmus.xcodeproj \
		-scheme dmus \
		-configuration Release \
		-destination 'generic/platform=macOS' \
		CONFIGURATION_BUILD_DIR=$(release_dir) \
		-quiet
	touch $@


$(TMP)/checked-iOS.stamp : $(src_files) | $$(dir $$@)
	xcodebuild test \
		-project dmus.xcodeproj \
		-scheme dmus \
		-destination 'platform=iOS Simulator,name=$(IOS_CHECK_DEVICE)' \
		-quiet
	touch $@


$(TMP)/checked-macOS.stamp : $(src_files) | $$(dir $$@)
	xcodebuild test \
		-project dmus.xcodeproj \
		-scheme dmus \
		-destination 'platform=macOS,arch=$(arch)' \
		-quiet
	touch $@


# use a stamp file since the disk image name contains a space and thus can't be
# a target name
$(TMP)/made-disk-image.stamp : $(TMP)/built-release.stamp scripts/make-dmg.sh
	scripts/make-dmg.sh "$(app)" $(TMP)
	touch $@
