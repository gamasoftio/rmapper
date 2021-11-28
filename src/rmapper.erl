%% @doc
%% A module to encode and decode Erlang's Record.
%%
%% The rmapper module aims to take away the boilerplate of implementing
%% mapping functions from and to Erlang's records.
%%
%% This module is based on the idea that a Record should have a unique
%% mapping specification for encoding and decoding, per format to encode/decode.
%% A same record can then easily be re-used to encode from/to JSON
%% but also from/to your database layer, only the specification would change.
%%
%% @end
%%
%% @author Gaston Siffert

-module(rmapper).

-export([
    field_spec/3,
    field_spec/2
]).
-export([
    encode/2,
    decode/3
]).

-type field_name() :: any().
-type field_value() :: any().
-type mapper_function() :: fun((field_value()) -> field_value()).

-record(field_spec, {
    name :: field_name(),
    index :: non_neg_integer(),
    mapper :: mapper_function()
}).

%%%----------------------------------------------------------------------------
%%% Functions to build the specification.
%%%----------------------------------------------------------------------------

%% @doc
%% Create the specification for a field.
%%
%% The specification created with this function will use
%% the MapperFunction during the encoding/decoding
%% to transform the data into the right format.
%%
%% Example:
%% ```
%% rmapper:field_spec(<<"name">>, #country.name, fun string:titlecase/1)
%% '''
%%
%% @end

-spec field_spec(field_name(), non_neg_integer(), mapper_function()) -> #field_spec{}.
field_spec(Name, Index, MapperFunction) ->
    #field_spec{name = Name, index = Index, mapper = MapperFunction}.

%% @doc
%% Create the specification for a field.
%%
%% The specification created with this function will
%% not transform the data during encoding/decoding.
%%
%% Example:
%% ```
%% rmapper:field_spec(<<"name">>, #country.name)
%% '''
%%
%% @end

-spec field_spec(field_name(), non_neg_integer()) -> #field_spec{}.
field_spec(Name, Index) ->
    field_spec(Name, Index, fun id/1).

%%%----------------------------------------------------------------------------
%%% Encoding and decoding functions.
%%%----------------------------------------------------------------------------

-type record() :: tuple().

-type property() :: {field_name(), field_value()}.

%% @doc
%% Encode the Record to a PropList.
%%
%% Example:
%% ```
%% Record = #country{name = <<"Netherlands">>, country_code = <<"NL">>, currency_code = <<"EUR">>},
%% Spec = [
%%    rmapper:field_spec(<<"name">>, #country.name),
%%    rmapper:field_spec(<<"country_code">>, #country.country_code),
%%    rmapper:field_spec(<<"currency_code">>, #country.currency_code)
%% ],
%% rmapper:encode(Record, Spec).
%%
%% [{<<"currency_code">>, <<"EUR">>}, {<<"country_code">>, <<"NL">>}, {<<"name">>, <<"Netherlands">>}]
%% '''
%%
%% @end

-spec encode(record(), list(#field_spec{})) -> list(property()).
encode(Record, FieldSpecs) ->
    lists:foldl(
        fun(Spec, Acc) ->
            case element(Spec#field_spec.index, Record) of
                undefined -> Acc;
                Value ->
                    #field_spec{name = Name, mapper = Mapper} = Spec,
                    [{Name, Mapper(Value)} | Acc]
            end
        end,
        [],
        FieldSpecs
    ).

%% @doc
%% Decode the Record from a PropList.
%%
%% Example:
%% ```
%% PropList = [{<<"currency_code">>, <<"EUR">>}, {<<"country_code">>, <<"NL">>}, {<<"name">>, <<"Netherlands">>}],
%% Spec = [
%%    rmapper:field_spec(<<"name">>, #country.name),
%%    rmapper:field_spec(<<"country_code">>, #country.country_code),
%%    rmapper:field_spec(<<"currency_code">>, #country.currency_code)
%% ],
%% rmapper:decode(#country{}, Spec, PropList).
%%
%% #country{name = <<"Netherlands">>, country_code = <<"NL">>, currency_code = <<"EUR">>}
%% '''
%%
%% @end

-spec decode(record(), list(#field_spec{}), list(property())) -> record().
decode(Record, FieldSpecs, PropList) ->
    SpecMap = spec_to_map(FieldSpecs),
    lists:foldl(
        fun({Key, Value}, NewRecord) ->
            case maps:get(Key, SpecMap, not_found) of
                not_found ->
                    NewRecord;
                #field_spec{index = Index, mapper = Mapper} ->
                    setelement(Index, NewRecord, Mapper(Value))
            end
        end,
        Record,
        PropList
    ).

%%%----------------------------------------------------------------------------
%%% Private functions
%%%----------------------------------------------------------------------------

-spec id(any()) -> any().
id(X) -> X.

-spec spec_to_map(list(#field_spec{})) -> #{ field_name() := field_value() }.
spec_to_map(FieldSpecs) ->
    lists:foldl(
        fun(#field_spec{name = Name} = Spec, Acc) ->
            maps:put(Name, Spec, Acc)
        end,
        #{},
        FieldSpecs
    ).
