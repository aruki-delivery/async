async
=====
*Asynchronous execution*

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

Async provides a parameter to specify the number of background process for each CPU core (the default value is 1, i.e. in a system with 2 cores the system will start 2 * 1 = 2 process for each job queue).

To change the default value, set value of the property "processes_by_core" on your config file.

```erlang
[
{async, [
	{processes_by_core, 5}
	]
}
].
```


Starting async
--------------

Async default job queue is created automatically on the first job.


```erlang
ok = application:start(async).
```


Using async
-----------

* Execution of anonymous functions.
```erlang
async:run(fun() ->
		io:format("Hello from ~p~n", [self()])
	end).
```

* Execution of function by providing the 3 parameters; ModuleName, FunctionName and Arguments.
```erlang
async:run(io, format, ["Hello from ~p~n", [self()]]).
```


Creating custom queues
----------------------

Async automatically creates custom job queues on the first job submission.

```erlang
async:run(test_job_queue, fun() ->
		io:format("Hello from ~p~n", [self()])
	end).

	
async:run(test_job_queue, io, format, ["Hello from ~p~n", [self()]]).
```
