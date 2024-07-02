////////////////////////////////////////////////////////////////////////////
// Code of the tester
////////////////////////////////////////////////////////////////////////////

errordomain TestError {
	SIGNALED
}

struct ShellInfo {
	string output;
	string errput;
	int status;
}

public int Nb_max_test = 0;
public int Max_async_test = 0;
public int Max_process = 0;
public int res = 0;

async void add_test(string command, string []?av = null) {
	string[] avx = av.copy();

	++Nb_max_test;
	++Max_async_test;
	while (Max_process >= jobs_thread) {
		Idle.add(add_test.callback);
		yield;
	}
	++Max_process;
	try {
		res += yield test(command, avx);
	}
	catch (Error e) {
	warning(e.message);
	}
	--Max_async_test;
	--Max_process;
}

/**
 * Run Minishell with a command and return the output and the status
 */
async ShellInfo run_minishell (string cmd, string []?av) throws Error {
	Cancellable timeout = new Cancellable();
	ShellInfo result = {};
	Subprocess process;

	if (print_leak)
		process = new Subprocess.newv ({"valgrind", "--leak-check=full", minishell_emp}, STDIN_PIPE | STDERR_PIPE | STDOUT_PIPE);
	else
		process = new Subprocess.newv ({minishell_emp, "--no-clear"}, STDIN_PIPE | STDOUT_PIPE | SubprocessFlags.STDERR_SILENCE);

	var uid = Timeout.add (4000, ()=> {
		timeout.cancel();
		process.force_exit ();
		return false;
	});

	if (av == null)
		yield process.communicate_utf8_async (cmd + "\n", timeout, out result.output, out result.errput);
	else {
		var arguments = new StringBuilder(cmd);
		arguments.append_c ('\n');
		foreach (unowned var arg in av) {
			arguments.append(arg);
			arguments.append_c ('\n');
		}
		yield process.communicate_utf8_async (arguments.str, timeout, out result.output, out result.errput);
	}
	yield process.wait_async (timeout);
	Source.remove (uid);
	
	if (process.get_if_signaled ()) {
		var sig = process.get_term_sig ();
		throw new TestError.SIGNALED(strsignal(sig));
	}
	result.status = process.get_exit_status ();


	return result;
}

/**
 * Run Bash with a command and return the output and the status
 */
async ShellInfo run_bash (string cmd, string []?av) throws Error {
	ShellInfo result = {};

	var arguments = new StringBuilder(cmd);
	arguments.append_c ('\n');
	if (av != null) {
		foreach (unowned var arg in av) {
			arguments.append(arg);
			arguments.append_c ('\n');
		}
	}

	var process = new Subprocess.newv ({"bash"}, STDIN_PIPE | STDERR_PIPE | STDOUT_PIPE);

	yield process.communicate_utf8_async (arguments.str, null, out result.output, out result.errput);
	yield process.wait_async ();

	result.status = process.get_exit_status ();

	return result;
}


static bool is_okay (ShellInfo minishell, ShellInfo bash) {
	bool ret = true;
	if (print_output && minishell.output != bash.output) {
		ret = false;
	}
	if (print_status && minishell.status != bash.status) {
		ret = false;
	}
	if (print_leak) {
		int malloc = 0;
		unowned string tmp = minishell.errput;
		int index = 0;

		do {
			index = tmp.index_of("definitely lost: ", 4);
			if (index != -1) {
				int m;
				tmp = tmp.offset(index);
				tmp.scanf ("definitely lost: %d bytes", out m); 
				malloc += m;
			}
		} while (index != -1);

		if (malloc != 0) {
			printerr("\033[91mMemory leak: %d bytes\033[0m\n", malloc);
			ret = false;
		}
	}
	return ret;
}


/**
 * Run Bash and Minishell test (command) and compare it and print the result !
 */
async int test (string command, string []?av = null) throws Error {
	try {
		//////////////////////////
		// Run Minishell
		//////////////////////////
		var minishell = yield run_minishell (command, av);

		//////////////////////////
		// Parse the output
		//////////////////////////
		
		unowned string output = minishell.output;
		string minishell_output = "";
		int index;

		index = output.index_of("SupraVala: ");
		// If the output doesn't contain "SupraVala: " we just return the output
		if (index == -1)
			minishell_output += output;
		// Get all output between the Prompt and the next Prompt
		while (index != -1) {
			output = output.offset(index + 11);
			output = output.offset(output.index_of_char ('\n') + 1);

			index = output.index_of("SupraVala: ");
			if (index == -1) {
				minishell_output += output;
			}
			else
				minishell_output += output[0: index];
		}

		minishell.output = (owned)minishell_output;


		//////////////////////////
		// Run Bash
		//////////////////////////

		var bash = yield run_bash (command, av);

		//////////////////////////
		// Print the result
		//////////////////////////
		if (print_only_error == false) {
			print ("\033[36;1mTest\033[0m [%s]", command);
			foreach (unowned var arg in av) {
				print (" [%s]", arg);
			}
		}
		if (is_okay (minishell, bash)) {
			if (print_only_error == false)
				print ("\033[32;1m[OK]\033[0m");
		}
		else {
			if (print_only_error == true) {
				print ("\033[36;1mTest\033[0m [%s]", command);
				foreach (unowned var arg in av) {
					print (" [%s]", arg);
				}
			}
			print ("\033[31;1m[KO]\033[0m\n");
			if (print_status && minishell.status != bash.status) {
				printerr("\033[91mStatus mismatch:\033[0m\n");
				printerr("  Minishell: [%d]\n", minishell.status);
				printerr("  Bash: [%d]\n\n", bash.status);
			}
			if (print_output && minishell.output != bash.output) {
				printerr("\033[91mOutput mismatch:\033[0m\n");
				printerr("  Minishell: [%s]\n", minishell.output);
				printerr("  Bash: [%s]\n\n", bash.output);
			}
			return 0;
		}
		if (print_only_error == false)
			print("\n");
		return 1;
	}
	catch (Error e) {
		if (e is IOError.CANCELLED || e is TestError.SIGNALED) {
			print ("\033[36;1mTest\033[0m [%s]", command);
			print ("\033[31;1m[KO]\033[0m\n");
		}

		if (e is IOError.CANCELLED) {
			print("\033[31;1m[Timeout] %s\n\033[0m", e.message);
			return 0;
		}
		if (e is TestError.SIGNALED) {
			print("\033[31;1m[SEGFAULT] %s\n\033[0m", e.message);
			return 0;
		}
		throw e;
	}
}

////////////////////////////////////////////////////////////////////////////
///	Log handler (Function to print the log like warning, error, etc...)
////////////////////////////////////////////////////////////////////////////

public void log_hander () {
	Log.set_default_handler((type, level, message)=> {
		unowned string real_message;
		var len = message.index_of_char(':') + 1;
		real_message = message.offset(len);
		len += real_message.index_of_char(':') + 2;
		real_message = message.offset(len);

		switch (level) {
			case LogLevelFlags.LEVEL_WARNING:
				print("\033[33m[WARNING]\033[0m: %s \033[35m(", real_message);
				stdout.write(message[0:len - 2].data);
				print(")\033[0m\n");
				break;
			case LogLevelFlags.LEVEL_CRITICAL:
				print("\033[35m[Critical]\033[0m: %s \033[35m(", real_message);
				stdout.write(message[0:len - 2].data);
				print(")\033[0m\n");
				break;
			case LogLevelFlags.LEVEL_MESSAGE:
				print("\033[32m[SupraPack]\033[0m: %s\n", message);
				break;
			case LogLevelFlags.LEVEL_DEBUG:
				if (Environment.get_variable ("G_MESSAGES_DEBUG") != null) {
					print("\033[35m[Debug]\033[0m: %s \033[35m(", real_message);
					stdout.write(message[0:len - 2].data);
					print(")\033[0m\n");
				}
				break;
			case LogLevelFlags.LEVEL_INFO:
				if (type == null)
					print("\033[35m[Info]\033[0m: %s\n", real_message);
				else
					print("%s: %s\n", type, real_message);
				break;
			case LogLevelFlags.FLAG_RECURSION:
			case LogLevelFlags.FLAG_FATAL:
			case LogLevelFlags.LEVEL_ERROR:
			default:
				print("\033[31m[Error]\033[0m: %s \033[35m(", real_message);
				stdout.write(message[0:len - 2].data);
				print(")\033[0m\n");
				Process.exit(-1);
		}
	});
}
