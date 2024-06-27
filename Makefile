all:
	valac main.vala core.vala --pkg=posix --pkg=gio-2.0 -X -O2 -X -w 
	valac fake_readline.vala --pkg=gmodule-2.0 --library=readline -X --shared -o fake_readline.so -X -fpic -X -w
run: all
	./main
