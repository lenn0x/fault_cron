SHELL=/bin/sh
 
EFLAGS=-pa ebin -o ebin
 
all: compile
 
ebins:
	test -d ebin || mkdir ebin
	erl $(EFLAGS) -make
	cp src/*.app ebin
 
compile: ebins
	erlc -W -v $(EFLAGS) src/*.erl
 
clean:
	rm -rf ebin
