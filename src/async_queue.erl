%%
%% Copyright 2016 Joaquim Rocha <jrocha@gmailbox.org>
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

-module(async_queue).

-include("async.hrl").

%% ====================================================================
%% API functions
%% ====================================================================

-export([start_link/0, start/0]).
-export([run/2, run/4]).
-export([running_count/1, queue_size/1]).

-export([init/1, system_continue/3, system_terminate/4, system_code_change/4]).

start_link() ->
  proc_lib:start_link(?MODULE, init, [self()]).

start() ->
  proc_lib:start(?MODULE, init, [self()]).

% functions

run(Pid, Fun) when is_pid(Pid), is_function(Fun, 0) -> send_job(Pid, Fun);
run(_Pid, _Fun) -> {error, invalid_function}.

run(Pid, Module, Function, Args) when is_pid(Pid), is_atom(Module), is_atom(Function), is_list(Args) ->
  run(Pid, fun() -> apply(Module, Function, Args) end);
run(_Pid, _Module, _Function, _Args) -> {error, invalid_request}.

running_count(Pid) when is_pid(Pid) -> call(Pid, running);
running_count(_Pid) -> {error, invalid_request}.

queue_size(Pid) when is_pid(Pid) -> call(Pid, size);
queue_size(_Pid) -> {error, invalid_request}.

%% ====================================================================
%% Internal functions
%% ====================================================================

-record(state, {queue, count, max}).

init(Parent) ->
  Debug = sys:debug_options([]),
  proc_lib:init_ack({ok, self()}),
  {ok, Multiplier} = application:get_env(async, processes_by_core),
  Max = erlang:system_info(schedulers) * Multiplier,
  State = #state{queue = queue:new(), count = 0, max = Max},
  loop(Parent, Debug, State).

loop(Parent, Debug, State) ->
  Msg = receive
          Input -> Input
        end,
  handle_msg(Msg, Parent, Debug, State).

handle_msg({system, From, Request}, Parent, Debug, State) ->
  sys:handle_system_msg(Request, From, Parent, ?MODULE, Debug, State);
handle_msg({'DOWN', Ref, _, _, _}, Parent, Debug, State) ->
  NewState = handle_terminated(Ref, State),
  loop(Parent, Debug, NewState);
handle_msg(?job(Fun), Parent, Debug, State) ->
  NewState = process(Fun, State),
  loop(Parent, Debug, NewState);
handle_msg(?request(From, Ref, Request), Parent, Debug, State) ->
  handle_request(From, Ref, Request, State),
  loop(Parent, Debug, State);
handle_msg(_Msg, Parent, Debug, State) ->
  loop(Parent, Debug, State).

system_continue(Parent, Debug, State) -> loop(Parent, Debug, State).
system_terminate(Reason, _Parent, _Debug, _State) -> exit(Reason).
system_code_change(State, _Module, _OldVsn, _Extra) -> {ok, State}.

handle_terminated(Ref, State = #state{queue = Queue, count = Count}) ->
  case queue:out(Queue) of
    {empty, _} -> State#state{count = Count - 1};
    {{value, Fun}, NewQueue} ->
      {_, _NewRef} = erlang:spawn_monitor(Fun),
      State#state{queue = NewQueue}
  end.

process(Fun, State = #state{queue = Queue, count = Max, max = Max}) ->
  NewQueue = queue:in(Fun, Queue),
  State#state{queue = NewQueue};
process(Fun, State = #state{count = Count}) ->
  {_, _Ref} = erlang:spawn_monitor(Fun),
  State#state{count = Count + 1}.

handle_request(From, Ref, Request, State) ->
  spawn(fun() ->
    Reply = get_reply(Request, State),
    From ! ?response(Ref, Reply)
        end).

get_reply(running, #state{count = Count}) ->
  Count;
get_reply(size, #state{queue = Queue}) ->
  queue:len(Queue);
get_reply(_Request, _State) -> {error, invalid_request}.

send_job(Pid, Fun) ->
  Pid ! ?job(Fun),
  ok.

call(Pid, Msg) ->
  Ref = make_ref(),
  Pid ! ?request(self(), Ref, Msg),
  receive
    ?response(Ref, Value) -> Value
  after 5000 -> {error, timeout}
  end.