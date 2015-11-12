%%
%% Copyright 2015 Joaquim Rocha <jrocha@gmailbox.org>
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

% application
start(_Type, _Args) ->
	Multiplier = application:get_env(async, processes_by_core, 1),
	WorkerCount = erlang:system_info(schedulers) * Multiplier,
	worker_pool_sup:start_pool(?MODULE, WorkerCount, {?MODULE, start_link, []}).

stop(_State) -> ok.

% pool
start_link() ->
	proc_lib:start_link(?MODULE, init, [self()]).

% functions

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

process(Request, _State) ->
	case Request of
		{run, Fun} -> Fun();
		{run, Fun, Args} ->	apply(Fun, Args);
		{run, Module, Function, Args} -> apply(Module, Function, Args);
		_ -> ok
	end.
