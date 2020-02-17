%%%-------------------------------------------------------------------
%%% @doc
%%%
%%% @end
%%%-------------------------------------------------------------------
-module(google_chat_handler).
-export([init/2, terminate/3, is_valid_event/1]).

is_valid_event(Event) ->
  try
    Type = maps:get(<<"type">>, Event),
    true = is_binary(Type),
    true = Type =/= <<"">>,
    Token = maps:get(<<"token">>, Event),
    true = is_binary(Token),
    true = Token =/= <<"">>,
    lager:info("Got valid request"),
    true
  catch
    Class:Reason:Stacktrace ->
      lager:error("Got invalid request body"),
      lager:error("Could not recognize entities"),
      lager:error(
        "~nStacktrace:~s",
        [lager:pr_stacktrace(Stacktrace, {Class, Reason})]
      ),
      false
  end.

response_for_event(Start, Request, AnswerFn, Event) ->
  lager:info("got event: ~p", [Event]),
  IsValidEvent = is_valid_event(Event),
  if
    (IsValidEvent == true) ->
      {ok, GoogleChatApiToken} = application:get_env(samson, google_chat_api_token),
      RequestToken = maps:get(<<"token">>, Event, ""),
      if
        GoogleChatApiToken == RequestToken ->
          Answer = AnswerFn(Event),
          endpoints:response(Start, Request, 200, #{text => Answer});
        true ->
          lager:info("Unauthorized access"),
          endpoints:response(Start, Request, 401, #{error => <<"unauthorized">>})
      end;
    true ->
      lager:info("Invalid body given"),
      endpoints:response(Start, Request, 400, #{error => <<"The supplied body is invalid">>})
  end.

response_for_body(Start, Request, AnswerFn) ->
  {ReadBodySuccessful, RawEvent, _} = cowboy_req:read_body(Request),
  if
    ReadBodySuccessful == ok ->
      Event = jiffy:decode(RawEvent, [return_maps]),
      response_for_event(Start, Request, AnswerFn, Event);
    true ->
      endpoints:response(Start, Request, 400, #{error => <<"The supplied body is invalid">>})
  end.

init(Request, [AnswerFn]) ->
  Start = os:system_time(),
  <<"POST">> = cowboy_req:method(Request),
  HasBody = cowboy_req:has_body(Request),
  if
    HasBody == true ->
      Response = response_for_body(Start, Request, AnswerFn),
      {ok, Response, [AnswerFn]};
    true ->
      lager:info("No body given"),
      Response = endpoints:response(Start, Request, 400, #{error => <<"Please supply a body">>}),
      {ok, Response, [AnswerFn]}
  end.

terminate(_Reason, _Req, _State) -> ok.
