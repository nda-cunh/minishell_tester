public delegate string d_readline (string prompt);


Module? module = null;
d_readline func = null;

public string readline (string prompt) {
	if (module == null) {
		void *symbol = null;
		module = Module.open ("libreadline.so", ModuleFlags.LAZY);
		module.symbol ("readline", out symbol);
		if (symbol == null)
			error("Can't load ReadLine()\n");
		func = (d_readline)symbol;
	}
    return func("SupraVala: ");
}
