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

caravan.cmi: caravan _build
	@cp ../../_build/src/caravan/caravan.cmi _build

caravan.cma: caravan _build
	@cp ../../_build/src/caravan/caravan.cma _build

caravan:
	@cd ../.. && make && cd -

_build:
	@mkdir -p _build
