all: clean deps riak_crud.byte
	@./riak_crud.byte

riak_crud.byte: caravan.cmi caravan.cma
	@ocamlbuild \
		-tag thread \
		-use-ocamlfind \
		-package core,async,textutils,cohttp.async \
		-lib caravan \
		riak_crud.byte

deps:
	@opam install --yes core async textutils cohttp

clean:
	@ocamlbuild -clean

caravan.cmi: _build
	@cp ../../_build/src/caravan/caravan.cmi _build

caravan.cma: _build
	@cp ../../_build/src/caravan/caravan.cma _build

_build:
	@mkdir -p _build
