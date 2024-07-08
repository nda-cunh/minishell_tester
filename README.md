Please do not use it for correction

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
  -o, --no-output                    Don't Display error-output
  -s, --no-status                    Don't Display error-status
  -m, --minishell=Minishell Path     the path of minishell default: '../minishell'
  -j, --jobs=num of jobs             The number of thread jobs by default is number of cpu
  -v, --leak                         Add Leak test (is too slow)

```
