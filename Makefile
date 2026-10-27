.PHONY: check clean

check:
	xcodebuild test \
		-project dmus.xcodeproj \
		-scheme dmus \
		-destination 'platform=macOS,arch=$(shell uname -m)' \
		-derivedDataPath DerivedData \
		-quiet

clean:
	rm -rf *.profraw
	rm -rf DerivedData
	rm -rf tmp
