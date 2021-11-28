-module(rmapper_test).

-include_lib("eunit/include/eunit.hrl").

-record(country, {
    name,
    country_code,
    currency_code
}).

to_ddb_string(Value) -> {s, Value}.

from_ddb_string({s, Value}) -> Value.

encode_test_() ->
    Tests = [
        {
            "Ignore undefined fields",
            [
                rmapper:field_spec(<<"name">>, #country.name),
                rmapper:field_spec(<<"country_code">>, #country.country_code),
                rmapper:field_spec(<<"currency_code">>, #country.currency_code)
            ],
            #country{name = <<"Netherlands">>},
            [{<<"name">>, <<"Netherlands">>}]
        },
        {
            "Ignore unspecified fields",
            [
                rmapper:field_spec(<<"name">>, #country.name)
            ],
            #country{name = <<"Netherlands">>, country_code = <<"NL">>, currency_code = <<"EUR">>},
            [{<<"name">>, <<"Netherlands">>}]
        },
        {
            "Encode everything",
            [
                rmapper:field_spec(<<"name">>, #country.name),
                rmapper:field_spec(<<"country_code">>, #country.country_code),
                rmapper:field_spec(<<"currency_code">>, #country.currency_code)
            ],
            #country{name = <<"Netherlands">>, country_code = <<"NL">>, currency_code = <<"EUR">>},
            [{<<"currency_code">>, <<"EUR">>}, {<<"country_code">>, <<"NL">>}, {<<"name">>, <<"Netherlands">>}]
        },
        {
            "Encode to DDB format",
            [
                rmapper:field_spec(<<"name">>, #country.name, fun to_ddb_string/1),
                rmapper:field_spec(<<"country_code">>, #country.country_code, fun to_ddb_string/1),
                rmapper:field_spec(<<"currency_code">>, #country.currency_code, fun to_ddb_string/1)
            ],
            #country{name = <<"Netherlands">>, country_code = <<"NL">>, currency_code = <<"EUR">>},
            [
                {<<"currency_code">>, {s, <<"EUR">>}},
                {<<"country_code">>, {s, <<"NL">>}},
                {<<"name">>, {s, <<"Netherlands">>}}
            ]
        }
    ],
    [
        {
            TestName,
            ?_assertEqual(Expected, rmapper:encode(Record, Spec))
        }
        ||
        {TestName, Spec, Record, Expected} <- Tests
    ].

decode_test_() ->
    Tests = [
        {
            "Ignore undefined fields",
            [
                rmapper:field_spec(<<"name">>, #country.name),
                rmapper:field_spec(<<"country_code">>, #country.country_code),
                rmapper:field_spec(<<"currency_code">>, #country.currency_code)
            ],
            [{<<"name">>, <<"Netherlands">>}],
            #country{name = <<"Netherlands">>}
        },
        {
            "Ignore unspecified fields",
            [
                rmapper:field_spec(<<"name">>, #country.name)
            ],
            [{<<"currency_code">>, <<"EUR">>}, {<<"country_code">>, <<"NL">>}, {<<"name">>, <<"Netherlands">>}],
            #country{name = <<"Netherlands">>}
        },
        {
            "Decode everything",
            [
                rmapper:field_spec(<<"name">>, #country.name),
                rmapper:field_spec(<<"country_code">>, #country.country_code),
                rmapper:field_spec(<<"currency_code">>, #country.currency_code)
            ],
            [{<<"currency_code">>, <<"EUR">>}, {<<"country_code">>, <<"NL">>}, {<<"name">>, <<"Netherlands">>}],
            #country{name = <<"Netherlands">>, country_code = <<"NL">>, currency_code = <<"EUR">>}
        },
        {
            "Decode from DDB format",
            [
                rmapper:field_spec(<<"name">>, #country.name, fun from_ddb_string/1),
                rmapper:field_spec(<<"country_code">>, #country.country_code, fun from_ddb_string/1),
                rmapper:field_spec(<<"currency_code">>, #country.currency_code, fun from_ddb_string/1)
            ],
            [
                {<<"currency_code">>, {s, <<"EUR">>}},
                {<<"country_code">>, {s, <<"NL">>}},
                {<<"name">>, {s, <<"Netherlands">>}}
            ],
            #country{name = <<"Netherlands">>, country_code = <<"NL">>, currency_code = <<"EUR">>}
        }
    ],
    [
        {
            TestName,
            ?_assertEqual(Expected, rmapper:decode(#country{}, Spec, PropList))
        }
        ||
        {TestName, Spec, PropList, Expected} <- Tests
    ].
