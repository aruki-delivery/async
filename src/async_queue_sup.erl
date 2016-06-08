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

-module(async_queue_sup).

-behaviour(supervisor).

-export([init/1]).

%% ====================================================================
%% API functions
%% ====================================================================
-export([start_link/0]).
-export([start_queue/1]).

-define(SERVER, {local, ?MODULE}).

start_link() ->
  supervisor:start_link(?SERVER, ?MODULE, []).

start_queue(JobQueue) ->
  supervisor:start_child(?MODULE, [JobQueue]).

%% ====================================================================
%% Behavioural functions
%% ====================================================================

init([]) ->
  error_logger:info_msg("~p [~p] Starting...\n", [?MODULE, self()]),
  Queue = {async_queue, {async_queue, start, []}, permanent, infinity, worker, [async_queue]},
  {ok, {{simple_one_for_one, 10, 60}, [Queue]}}.

%% ====================================================================
%% Internal functions
%% ====================================================================