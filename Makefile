.PHONY: check clean release

APP = DerivedData/Build/Products/Release/Dmus.app

check:
	xcodebuild test \
		-project dmus.xcodeproj \
		-scheme dmus \
		-destination 'platform=macOS,arch=$(shell uname -m)' \
		-derivedDataPath DerivedData \
		-quiet

release:
	xcodebuild build \
		-project dmus.xcodeproj \
		-scheme dmus \
		-configuration Release \
		-destination 'generic/platform=macOS' \
		-derivedDataPath DerivedData \
		-quiet
	scripts/make-dmg.sh $(APP) build

clean:
	rm -rf *.profraw
	rm -rf build
	rm -rf DerivedData
	rm -rf tmp
