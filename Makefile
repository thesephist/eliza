all: run

run:
	rlwrap ink ./main.ink

check:
	ink ./test/*.ink
t: check

fmt:
	inkfmt fix lib/*.ink test/*.ink *.ink
f: fmt

fmt-check:
	inkfmt lib/*.ink test/*.ink *.ink
fk: fmt-check

# web UI build tooling

# NOTE: Eliza itself is not compiled automatically. Instead, manually run
# `september translate` and remove lines related to dependency imports.

compile:
	echo '' > static/ink/bundle.js
	september translate lib/torus.js.ink | tee /dev/stderr >> static/ink/bundle.js
	september translate lib/ui.js.ink | tee /dev/stderr >> static/ink/bundle.js

watch:
	ls lib/*.js.ink | entr make compile
w: watch
