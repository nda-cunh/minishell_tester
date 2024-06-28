# Dependencies
- valac and a C compiler (gcc/clang/...)

# How use

```make```

```bash
./tester
```

if you want , you can just print error :)

```bash
./tester --only-error
```

```
Usage:
  tester [OPTION…] - Minishell Tester -

Help Options:
  -h, --help                         Show help options

Application Options:
  -e, --only-error                   Display Error and do not print [OK] test
  -o, --only-output                  Display only error-output
  -s, --only-status                  Display only error-status
  -m, --minishell=Minishell Path     the path of minishell default: '../minishell'
  -v, --leak                         Add Leak test (is too slow)
```
