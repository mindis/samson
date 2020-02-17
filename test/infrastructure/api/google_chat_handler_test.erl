%%%-------------------------------------------------------------------
%%% @doc
%%%
%%% @end
%%%-------------------------------------------------------------------
-module(google_chat_handler_test).

-include_lib("eunit/include/eunit.hrl").

is_empty_event_test() ->
  GivenEvent = #{},

  Actual = google_chat_handler:is_valid_event(GivenEvent),
  Expected = false,

  ?assertEqual(Expected, Actual).

is_empty_type_string_event_test() ->
  GivenEvent = #{
    <<"type">> => <<"">>,
    <<"user">> => #{
      <<"name">> => <<"bar">>
    }
  },

  Actual = google_chat_handler:is_valid_event(GivenEvent),
  Expected = false,

  ?assertEqual(Expected, Actual).

is_empty_user_name_string_event_test() ->
  GivenEvent = #{
    <<"type">> => <<"foo">>,
    <<"user">> => #{
      <<"name">> => <<"">>
    }
  },

  Actual = google_chat_handler:is_valid_event(GivenEvent),
  Expected = false,

  ?assertEqual(Expected, Actual).

is_valid_event_test() ->
  GivenEvent = #{
    <<"type">> => <<"foo">>,
    <<"user">> => #{
      <<"name">> => <<"bar">>
    }
  },

  Actual = google_chat_handler:is_valid_event(GivenEvent),
  Expected = true,

  ?assertEqual(Expected, Actual).
