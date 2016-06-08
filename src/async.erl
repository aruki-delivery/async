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

-include("async.hrl").

%% ====================================================================
%% API functions
%% ====================================================================

-export([run/1, run/2, run/3, run/4]).
-export([running_count/0, running_count/1, queue_size/0, queue_size/1]).

% functions

run(Fun) when is_function(Fun, 0) -> run(?DEFAULT_JOB_QUEUE, Fun);
run(_Fun) -> {error, invalid_function}.

run(JobQueue, Fun) when is_atom(JobQueue), is_function(Fun, 0) ->
  case get_pid(JobQueue) of
    {ok, Pid} -> async_queue:run(Pid, Fun);
    Other -> Other
  end;
run(_JobQueue, _Fun) -> {error, invalid_function}.

run(Module, Function, Args) when is_atom(Module), is_atom(Function), is_list(Args) ->
  run(?DEFAULT_JOB_QUEUE, Module, Function, Args);
run(_Module, _Function, _Args) -> {error, invalid_request}.

run(JobQueue, Module, Function, Args) when is_atom(JobQueue), is_atom(Module), is_atom(Function), is_list(Args) ->
  run(JobQueue, fun() -> apply(Module, Function, Args) end);
run(_JobQueue, _Module, _Function, _Args) -> {error, invalid_request}.

running_count() -> running_count(?DEFAULT_JOB_QUEUE).

running_count(JobQueue) when is_atom(JobQueue) ->
  case whereis(JobQueue) of
    undefined -> 0;
    Pid -> async_queue:running_count(Pid)
  end;
running_count(_JobQueue) -> {error, invalid_request}.

queue_size() -> queue_size(?DEFAULT_JOB_QUEUE).

queue_size(JobQueue) when is_atom(JobQueue) ->
  case whereis(JobQueue) of
    undefined -> 0;
    Pid -> async_queue:queue_size(Pid)
  end;
queue_size(_JobQueue) -> {error, invalid_request}.

%% ====================================================================
%% Internal functions
%% ====================================================================

get_pid(JobQueue) ->
  case whereis(JobQueue) of
    undefined -> async_queue_sup:start_queue(JobQueue);
    Pid -> {ok, Pid}
  end.