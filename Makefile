all:
	opam exec -- dune build @all
	cp -rf _build/default/bin/main.exe ochat

.PHONY: test
test:
	$(MAKE) -C test
	cp -rf _build/default/test/test.exe ochat-test

clean:
	rm -rf _build/
	rm -f ochat ochat-test
