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

