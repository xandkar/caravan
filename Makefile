OASIS_GENERATED_FILES :=  \
	setup.data \
	setup.ml \
	_tags


.PHONY: \
	all \
	build \
	clean \
	clean_both \
	clean_oasis \
	clean_ocaml \
	default \
	deps


default: \
	build

deps:
	@opam install --yes \
		oasis \
		core \
		async \
		textutils

all: \
	deps \
	clean_ocaml \
	setup.ml \
	setup.data \
	build

setup.ml:
	@oasis setup

setup.data: setup.ml
	@ocaml setup.ml -configure

build: setup.data
	@ocaml setup.ml -build

clean: clean_ocaml

clean_ocaml: setup.ml
	@ocaml setup.ml -clean

clean_oasis:
	@for file in $(OASIS_GENERATED_FILES); do \
		rm $$file || true; \
	done

clean_both: \
	clean_ocaml \
	clean_oasis
