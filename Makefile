fake_readline.so: fake_readline.vala
	valac fake_readline.vala --pkg=gmodule-2.0 --library=readline -X --shared -o fake_readline.so -X -fpic -X -w

tester: fake_readline.so main.vala core.vala
	valac main.vala core.vala --pkg=gio-2.0 -X -w -X -O3 -o tester

debug: fake_readline.so main.vala core.vala
	valac main.vala core.vala --pkg=gio-2.0 -X -w -X -O3 --debug -X -fsanitize=address -o tester

all: tester

re: clean all

clean:
	rm -f *.so *.c tester *.test

run: all
	./tester

.PHONY: all re clean run debug
