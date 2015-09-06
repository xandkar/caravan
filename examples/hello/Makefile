all: clean deps hello.byte
	@./hello.byte

hello.byte: caravan.cmi caravan.cma
	@ocamlbuild \
		-tag thread \
		-use-ocamlfind \
		-package core,async,textutils \
		-lib caravan \
		hello.byte

deps:
	@opam install --yes core async textutils

clean:
	@ocamlbuild -clean

caravan.cmi: _build
	@cp ../../_build/src/caravan/caravan.cmi _build

caravan.cma: _build
	@cp ../../_build/src/caravan/caravan.cma _build

_build:
	@mkdir -p _build
