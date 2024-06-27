fake_readline.so: fake_readline.vala
	valac fake_readline.vala --pkg=gmodule-2.0 --library=readline -X --shared -o fake_readline.so -X -fpic -X -w

tester: fake_readline.so main.vala core.vala
	valac tester.vala --pkg=gmodule-2.0 -X -L. -X -lreadline -X -w -o tester 

all: tester

re: clean all

clean:
	rm -f *.so *.c tester *.test

run: all
	./main
