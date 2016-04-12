%%
%% Copyright 2015-16 Joaquim Rocha <jrocha@gmailbox.org>
%% 
%% Licensed under the Apache License, Version 2.0 (the "License");
%% you may not use this file except in compliance with the License.
%% You may obtain a copy of the License at
%%
%%   http://www.apache.org/licenses/LICENSE-2.0
%%
%% Unless required by applicable law or agreed to in writing, software
%% distributed under the License is distributed on an "AS IS" BASIS,
%% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%% See the License for the specific language governing permissions and
%% limitations under the License.
%%

-module(async).

-behaviour(application).

%% ====================================================================
%% API functions
%% ====================================================================

-export([start/2, 
	stop/1]).

-export([start_link/0,
	init/1,
	system_continue/3,
	system_terminate/4,
	system_code_change/4]).

-export([run/1,
	run/2,
	run/3]).
	
-export([start_pool/2]).

% application
start(_Type, _Args) ->
	{ok, Multiplier} = application:get_env(processes_by_core),
	WorkerCount = erlang:system_info(schedulers) * Multiplier,
	start_pool(?MODULE, WorkerCount).

stop(_State) -> ok.

% pool
start_link() ->
	proc_lib:start_link(?MODULE, init, [self()]).

% functions

start_pool(PoolName, WorkerCount) when is_atom(PoolName), is_integer(WorkerCount) ->
	worker_pool_sup:start_pool(PoolName, WorkerCount, {?MODULE, start_link, []}).

run(Fun) when is_function(Fun, 0) -> 
	?MODULE ! {run, Fun},
	ok.

run(Fun, Args) when is_function(Fun) 
		andalso is_list(Args) -> 
	?MODULE ! {run, Fun, Args},
	ok.

run(Module, Function, Args) when is_atom(Module)
		andalso is_atom(Function)
		andalso is_list(Args) ->
	?MODULE ! {run, Module, Function, Args},
	ok.

%% ====================================================================
%% Internal functions
%% ====================================================================

init(Parent) -> 
	Debug = sys:debug_options([]),
	proc_lib:init_ack({ok, self()}), 
	State = [],
	loop(Parent, Debug, State).

loop(Parent, Debug, State) ->
	receive
		{system, From, Request} ->
			sys:handle_system_msg(Request, From, Parent, ?MODULE, Debug, State);
		Request ->
			process(Request, State),
			loop(Parent, Debug, State)
	end.

system_continue(Parent, Debug, State) -> loop(Parent, Debug, State).
system_terminate(Reason, _Parent, _Debug, _State) -> exit(Reason).
system_code_change(State, _Module, _OldVsn, _Extra) -> {ok, State}.

process({run, Fun}, _State) -> Fun();
process({run, Fun, Args}, _State) -> apply(Fun, Args);
process({run, Module, Function, Args}, _State) -> apply(Module, Function, Args);
process(_Request, _State) -> ok.
