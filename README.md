async
=====
*Asynchronous function execution*

Async consists on a worker pool for asynchronous execution of tasks (i.e. functions).
This utility should be useful for background tasks execution, without risking overloading the system by starting to many process.


Installation
------------

Using rebar:

```erlang
{deps, [
	{async, ".*", {git, "https://github.com/jjmrocha/async.git", "master"}}
]}.
```


Configuration
-------------

Async provides a parameter to specify the number of background process for each CPU core (the default value is 5, i.e. in a system with 2 cores the system will start 2 * 5 = 10 process).

To change the default value, set value of the property "processes_by_core" on your config file.

```erlang
[
{async, [
	{processes_by_core, "5}
	]
}
].
```


Starting async
--------------

Async worker pool is created automatically when the application starts.


```erlang
ok = application:start(async).
```


Using async
-----------

1. Execution of anonymous functions.
```erlang
async:run(fun() ->
		io:format("Hello from ~p~n", [self()])
	end).
```

2. Execution of function using function references (i.e. fun FunctionName/Arity).
```erlang
async:run(fun io:format/2, ["Hello from ~p~n", [self()]]).
```

3. Execution of function by providing the 3 parameters; ModuleName, FunctionName and Arguments.
```erlang
async:run(io, format, ["Hello from ~p~n", [self()]]).
```
