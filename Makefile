
.PHONY: \
	clean \
	build \
	build-with-env \
	release \
	release-with-env

clean:
	rm -rf ./zig-out
build:
	zig build
build-with-env:
	env $(cat .env | xargs) zig build
release:
	zig build -Doptimize=ReleaseFast
release-with-env:
	env $(cat .env | xargs) zig build -Doptimize=ReleaseFast
