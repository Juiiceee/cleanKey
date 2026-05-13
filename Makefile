.PHONY: build test package clean

build:
	swift build -c release --product CleanKey

test:
	swift test

package:
	./scripts/package_app.sh

clean:
	rm -rf .build
