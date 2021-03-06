%%%-------------------------------------------------------------------
%%% @doc
%%%
%%% @end
%%%-------------------------------------------------------------------
-module(intent_classifier).
-behaviour(gen_server).
-include("../metrics_registry_h.hrl").

-export([init/1, handle_call/3, handle_cast/2, start_link/1]).

-define(UNKNOWN_INTENT, {unknown, 1.0}).

start_link(IntentClassifierClient) ->
  gen_server:start_link({local, ?MODULE}, ?MODULE, [IntentClassifierClient], []).

init(IntentClassifierClient) ->
  {ok, IntentClassifierClient}.

by_score_desc(IntentA, IntentB) ->
  {_, ProbA} = IntentA,
  {_, ProbB} = IntentB,
  ProbB =< ProbA.

classify_intent(IntentClassifierClient, Text) ->
  try
    Intents = metrics_registry:metered_execution_duration(?INTENT_DURATION, IntentClassifierClient, [Text]),
    lager:info("Classified intents: ~p", [Intents]),
    if
      Intents == [] -> ?UNKNOWN_INTENT;
      true -> utils:first(lists:sort(fun by_score_desc/2, Intents))
    end
  catch
    Class:Reason:Stacktrace ->
      lager:error("Could not classify intent"),
      lager:error(
        "~nStacktrace:~s",
        [lager:pr_stacktrace(Stacktrace, {Class, Reason})]
      ),
      ?UNKNOWN_INTENT
  end.

handle_call({classifyIntent, _UserId, Message}, _From, [IntentClassifierClient]) ->
  lager:info("Starting intent classification for: ~p", [Message]),
  Intent = classify_intent(IntentClassifierClient, Message),
  lager:info("Chose intent: ~p", [Intent]),
  {reply, Intent, [IntentClassifierClient]};
handle_call(terminate, _From, State) ->
  lager:info("Intent classifier shutdown: Starting"),
  lager:info("Intent classifier shutdown: Done"),
  {stop, normal, ok, State}.

handle_cast(_Request, _State) ->
  erlang:error(not_implemented).
