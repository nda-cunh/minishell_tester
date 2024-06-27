public delegate string d_readline (string prompt);

public string readline (string prompt) {
    Module module;
    void *symbol;

    module = Module.open ("libreadline.so", ModuleFlags.LAZY);
    module.symbol ("readline", out symbol);
    if (symbol == null)
        error("Can't load ReadLine()\n");
    d_readline func = (d_readline)symbol;
    return func("SupraVala: ");
}
