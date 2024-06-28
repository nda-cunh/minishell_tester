////////////////////////////////////////////////////////////////////////////
// Code of the tester
////////////////////////////////////////////////////////////////////////////


struct ShellInfo {
	string output;
	string errput;
	int status;
}

/**
 * Run Minishell with a command and return the output and the status
 */
async ShellInfo run_minishell (string cmd, string []?av) throws Error {
	Cancellable timeout = new Cancellable();
	ShellInfo result = {};

	var subprocess = new Subprocess.newv        ({"../minishell"}, STDIN_PIPE | STDOUT_PIPE | SubprocessFlags.STDERR_SILENCE);
	var uid = Timeout.add (4000, ()=> {
		timeout.cancel();
		subprocess.force_exit ();
		return false;
	});

	if (av == null)
		yield subprocess.communicate_utf8_async (cmd + "\n", timeout, out result.output, out result.errput);
	else {
		var arguments = new StringBuilder(cmd);
		arguments.append_c ('\n');
		foreach (unowned var arg in av) {
			arguments.append(arg);
			arguments.append_c ('\n');
		}
		yield subprocess.communicate_utf8_async (arguments.str, timeout, out result.output, out result.errput);
	}
	yield subprocess.wait_async (timeout);
	Source.remove (uid);
	result.status = subprocess.get_exit_status ();

	return result;
}


/**
 * Run Bash with a command and return the output and the status
 */
async ShellInfo run_bash (string cmd, string []?av) {
	ShellInfo result = {};

	string command = cmd;

	if (av != null) {
		foreach (unowned var arg in av) {
			command += "; " + arg;
		}
	}

	var thread = new Thread<void>(null, ()=> {
		try {
			Process.spawn_sync (null, {"bash", "-c", command}, null, SEARCH_PATH, null, out result.output, out result.errput, out result.status);
		}
		catch (Error e) {
			warning(e.message);
		}
		Idle.add(run_bash.callback);
	});

	yield;
	thread.join ();

	return result;
}

/**
 * Run Bash and Minishell test (command) and compare it and print the result !
 */
async int test (string command, string []?av = null) throws Error {
	try {
		string minishell_output = "";
		//////////////////////////
		// Run Minishell
		//////////////////////////
		var minishell = yield run_minishell (command, av);

		var thread = new Thread<void>(null, ()=> {
			unowned string output;
			if (command.strip() == "") {
				output = minishell.output.offset(minishell.output.index_of("SupraVala: exit") + 15);
				minishell_output = output[0: output.last_index_of("SupraVala: exit")];
			}
			else {
				output = minishell.output;
				unowned string end;
				while (true) {
					output = output.offset(output.index_of("SupraVala: ") + 11);
					output = output.offset(output.index_of_char ('\n') + 1);
					minishell_output += output[0: output.index_of("SupraVala: ")];
					end = output.offset(output.index_of("SupraVala: "));
					if (end.index_of("SupraVala: ", 1) == -1) {
						break;
					}
				}
			}
			Idle.add(test.callback);
		});
		thread.join ();
		yield;


		//////////////////////////
		// Run Bash
		//////////////////////////

		var bash = yield run_bash (command, av);
		bash.status = bash.status >> 8;


		//////////////////////////
		// Print the result
		//////////////////////////
		if (print_only_error == false) {
			print ("\033[36;1mTest\033[0m [%s]", command);
			foreach (unowned var arg in av) {
				print (" [%s]", arg);
			}
		}
		if (minishell_output == bash.output && minishell.status == bash.status) {
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
			if (minishell.status != bash.status) {
				printerr("\033[91mStatus mismatch:\033[0m\n");
				printerr("  Minishell: [%d]\n", minishell.status);
				printerr("  Bash: [%d]\n\n", bash.status);
			}
			if (minishell_output != bash.output) {
				printerr("\033[91mOutput mismatch:\033[0m\n");
				printerr("  Minishell: [%s]\n", minishell_output);
				printerr("  Bash: [%s]\n\n", bash.output);
			}
			return 0;
		}
		if (print_only_error == false)
			print("\n");
		return 1;
	}
	catch (Error e) {
		if (e is IOError.CANCELLED) {
			print ("\033[36;1mTest\033[0m [%s]", command);
			print ("\033[31;1m[KO]\033[0m\n");
			print("\033[31;1m[Timeout] %s\n\033[0m", e.message);
			return 0;
		}
		throw e;
	}
}

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
