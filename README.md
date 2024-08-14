Please do not use it for correction

	Vous n'êtes pas obligé d'avoir 100/100 c'est à vous de jugez si un teste est obligatoire ou non.

# Dependencies
- valac and a C compiler (gcc/clang/...)

# How use

```make```

```bash
./tester
```

if you want , you can just print error :)  (run --help for more information)

```bash
./tester --only-error
./tester -e
```
# Memory Test 

'-v' (--leak) is very slow, it's a leak test it can test:
- uninitialized value
- conditional jump or move depends on uninitialised value 
- invalid read of size
- invalid write of size
- use after free
- lost memory


```bash
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
