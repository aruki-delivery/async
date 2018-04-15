%% @author joaquim.rocha

-module(test).

-behaviour(async_pool).

-export([init/1, handle_call/2, handle_cast/2, handle_info/2, terminate/2, code_change/3]).
%% ====================================================================
%% API functions
%% ====================================================================
-export([start/0, sleep/1]).
-export([test/2, test/3]).

start() ->
	async_pool:start({local, ?MODULE}, ?MODULE, [], []).

sleep(Delay) ->
	async_pool:cast(?MODULE, {sleep, Delay}).

test(0, _Delay, _Interval) -> ok;
test(Count, Delay, Interval) ->
	sleep(Delay),
	timer:sleep(Interval),
	test(Count -1, Delay).

test(Count, Delay) -> test(Count, Delay, 0).

%% ====================================================================
%% Behavioural functions
%% ====================================================================

init([]) ->
	{ok, []}.

handle_call(_Request, _State) -> 
	{reply, []}.

handle_cast({sleep, 0}, _State) ->
	%io:format("sleep -> ~p~n", [self()]),
	noreply;
handle_cast({sleep, Delay}, _State) ->
	%io:format("sleep -> ~p (~p)~n", [self(), Delay]),
	timer:sleep(Delay),
	noreply;
handle_cast(_Request, _State) -> 
	noreply.

handle_info(_Info, _State) -> 
	noreply.

terminate(_Reason, _State) ->
	ok.

code_change(_OldVsn, State, _Extra) ->
	{ok, State}.

%% ====================================================================
%% Internal functions
%% ====================================================================


