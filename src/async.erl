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

-export([start_link/0, init/1, system_continue/3, system_terminate/4, system_code_change/4]).

-export([run/1, run/2, run/3, run/4]).
-export([queues/0, running_count/0, running_count/1, size/1]).

start_link() ->
  proc_lib:start_link(?MODULE, init, [self()]).

% functions

run(Fun) when is_function(Fun, 0) -> run(?DEFAULT_JOB_QUEUE, Fun);
run(_Fun) -> {error, invalid_function}.

run(JobQueue, Fun) when is_atom(JobQueue), is_function(Fun, 0) -> send_job(JobQueue, Fun);
run(_JobQueue, _Fun) -> {error, invalid_function}.

run(Module, Function, Args) when is_atom(Module), is_atom(Function), is_list(Args) ->
  run(?DEFAULT_JOB_QUEUE, Module, Function, Args);
run(_Module, _Function, _Args) -> {error, invalid_request}.

run(JobQueue, Module, Function, Args) when is_atom(JobQueue), is_atom(Module), is_atom(Function), is_list(Args) ->
  run(JobQueue, fun() ->
    apply(Module, Function, Args)
                end);
run(_JobQueue, _Module, _Function, _Args) -> {error, invalid_request}.

queues() -> call(queues).

running_count() -> call(running).

running_count(JobQueue) when is_atom(JobQueue) -> call({running, JobQueue});
running_count(_JobQueue) -> {error, invalid_request}.

size(JobQueue) when is_atom(JobQueue) -> call({size, JobQueue});
size(_JobQueue) -> {error, invalid_request}.

%% ====================================================================
%% Internal functions
%% ====================================================================

-record(state, {job_queues, running}).
-record(job_queue, {queue, count, max}).

init(Parent) ->
  register(?MODULE, self()),
  Debug = sys:debug_options([]),
  proc_lib:init_ack({ok, self()}),
  State = #state{job_queues = dict:new(), running = dict:new()},
  error_logger:info_msg("~p starting on [~p]...\n", [?MODULE, self()]),
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
handle_msg(?job(JobQueue, Fun), Parent, Debug, State) ->
  NewState = process(JobQueue, Fun, State),
  loop(Parent, Debug, NewState);
handle_msg(?request(From, Ref, Request), Parent, Debug, State) ->
  handle_request(From, Ref, Request, State),
  loop(Parent, Debug, State);
handle_msg(_Msg, Parent, Debug, State) ->
  loop(Parent, Debug, State).

system_continue(Parent, Debug, State) -> loop(Parent, Debug, State).
system_terminate(Reason, _Parent, _Debug, _State) -> exit(Reason).
system_code_change(State, _Module, _OldVsn, _Extra) -> {ok, State}.

handle_terminated(Ref, State = #state{job_queues = Jobs, running = RunningJobs}) ->
  case dict:find(Ref, RunningJobs) of
    error -> State;
    {ok, JobQueue} ->
      NewRunningJobs1 = dict:erase(Ref, RunningJobs),
      Job = #job_queue{queue = Queue, count = Count} = find_job_queue(JobQueue, Jobs),
      case queue:out(Queue) of
        {empty, _} ->
          NewJob = Job#job_queue{count = Count - 1},
          NewJobs = dict:store(JobQueue, NewJob, Jobs),
          State#state{job_queues = NewJobs, running = NewRunningJobs1};
        {{value, Fun}, NewQueue} ->
          {_, NewRef} = erlang:spawn_monitor(Fun),
          NewRunningJobs2 = dict:store(NewRef, JobQueue, NewRunningJobs1),
          NewJob = Job#job_queue{queue = NewQueue},
          NewJobs = dict:store(JobQueue, NewJob, Jobs),
          State#state{job_queues = NewJobs, running = NewRunningJobs2}
      end
  end.

process(JobQueue, Fun, State = #state{job_queues = Jobs, running = RunningJobs}) ->
  Job = find_job_queue(JobQueue, Jobs),
  case Job of
    #job_queue{queue = Queue, count = Max, max = Max} ->
      NewQueue = queue:in(Fun, Queue),
      NewJob = Job#job_queue{queue = NewQueue},
      NewJobs = dict:store(JobQueue, NewJob, Jobs),
      State#state{job_queues = NewJobs};
    #job_queue{count = Count} ->
      {_, Ref} = erlang:spawn_monitor(Fun),
      NewRunningJobs = dict:store(Ref, JobQueue, RunningJobs),
      NewJob = Job#job_queue{count = Count + 1},
      NewJobs = dict:store(JobQueue, NewJob, Jobs),
      State#state{job_queues = NewJobs, running = NewRunningJobs}
  end.

handle_request(From, Ref, Request, State) ->
  spawn(fun() ->
    Reply = get_reply(Request, State),
    From ! ?response(Ref, Reply)
        end).

find_job_queue(JobQueue, Jobs) ->
  case dict:find(JobQueue, Jobs) of
    error ->
      {ok, Multiplier} = application:get_env(processes_by_core),
      Max = erlang:system_info(schedulers) * Multiplier,
      #job_queue{queue = queue:new(), count = 0, max = Max};
    {ok, Job} -> Job
  end.

get_reply(queues, #state{job_queues = Jobs}) -> dict:fetch_keys(Jobs);
get_reply(running, #state{running = RunningJobs}) -> dict:size(RunningJobs);
get_reply({running, JobQueue}, #state{job_queues = Jobs}) ->
  #job_queue{count = Count} = find_job_queue(JobQueue, Jobs),
  Count;
get_reply({size, JobQueue}, #state{job_queues = Jobs}) ->
  #job_queue{queue = Queue} = find_job_queue(JobQueue, Jobs),
  queue:len(Queue);
get_reply(_Request, _State) -> {error, invalid_request}.

send_job(JobQueue, Fun) ->
  ?MODULE ! ?job(JobQueue, Fun),
  ok.

call(Msg) ->
  Ref = make_ref(),
  ?MODULE ! ?request(self(), Ref, Msg),
  receive
    ?response(Ref, Value) -> Value
  after 5000 -> {error, timeout}
  end.