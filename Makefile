TMP ?= $(abspath tmp)

IOS_CHECK_DEVICE ?= iPhone 16e

app_files = $(shell find dmus -type f -not -name '.*')
arch = $(shell uname -m)
package_files = $(shell find dmusBase -type f -not -name '.*')
project_files = $(shell find dmus.xcodeproj -type f -not -name '.*')
release_dir = $(TMP)/Release
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
release : $(TMP)/Dmus-$(ver).dmg


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


# use a stamp file because `$(release_dir)/Dmus.app` is a directory
$(TMP)/built-release.stamp : $(src_files) | $(release_dir)
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


$(TMP)/Dmus-$(ver).dmg : $(TMP)/built-release.stamp scripts/make-dmg.sh
	scripts/make-dmg.sh $(release_dir)/Dmus.app $(TMP)
