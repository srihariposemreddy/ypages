-module(ypages_util).

-export([current_date_string/0, current_date_binary/0, current_bucket_name/0, compare_bucket_name/1]).
-export([current_hour_string/0, current_hour_binary/0, current_key_bucket/1,  compare_key_bucket/2]).
-export([extract_json/2]).

%% Date Related Functions
current_date_string() ->
    {Year, Month, Day} = date(),
    DateAsString = io_lib:format("~4..0w~2..0w~2..0w", [Year, Month, Day]),
    lists:flatten(DateAsString).
    
current_date_binary() ->
	list_to_binary(ypages_util:current_date_string()).


 %% Generating the Bucket name 
		
current_bucket_name() ->
	DateAsString = string:concat( ypages_util:current_date_string(), "_Pages"),
	list_to_binary(DateAsString).

compare_bucket_name(Dstring) ->
	DateAsString = lists:flatten(Dstring),
	list_to_binary(DateAsString).
		
%% Time Related Functions

current_hour_string() ->
	{Hour, _, _} = time(),
	TimeAsString = io_lib:format("~2..0w", [Hour]),
	lists:flatten(TimeAsString).
		
current_hour_binary() ->
	KeyAsString = string:concat("id_", ypages_util:current_hour_string()),
	io:format("key value ~p~n",[KeyAsString]),
	list_to_binary(KeyAsString).
	
current_key_bucket(RespId) ->
    CurHrBin = list_to_binary( ypages_util:current_hour_string() ),
    Sep = list_to_binary("_"),
    RId = list_to_binary(RespId),
    <<RId/binary, Sep/binary, CurHrBin/binary>>.
    
compare_key_bucket(RespId, Hr) ->
    CurHrBin = list_to_binary( Hr ),
    Sep = list_to_binary("_"),
    RId = list_to_binary(RespId),
    <<RId/binary, Sep/binary, CurHrBin/binary>>.

% json related functions
	
extract_json(CompareStringr, JsonString) ->
	DecodedJsonStruct = mochijson2:decode(JsonString),
	%JsonKeyBin = list_to_binary(JsonKey),
	CompareString = ["id"],
	case jsonValueStruct(CompareString,  DecodedJsonStruct) of
		{ok, JsonValue} ->
			io:format("...extracted:  Value = ~p ~n",[JsonValue]),
			{ok, JsonValue};
		{error, Err} ->
			io:format("...extracted:  Value = ~p ~n",[error, Err]),
			{error, Err}
	end.

jsonValueStruct(ComString, {struct, ListOfPairs}) when is_list(ListOfPairs) ->
	jsonValueStruct(ComString, ListOfPairs);

jsonValueStruct([], ListOfPairs) ->
	{error, key_not_found};

jsonValueStruct([Head|Tail], ListOfPairs) ->
	
	case jsonCompare(list_to_binary(Head), ListOfPairs) of
	 	{value, Value}  ->
	 		{ok, Value};
		{list, Value} ->
			jsonValueStruct(Tail, Value);
	 	{error, ErrString} ->
	 	    {error, ErrString}	
	end.

jsonCompare (Attribute, []) ->
       {error , "Not Found"};

jsonCompare(Attribute, [Head|Tail]) ->
	case Head of
	 	{Attribute, Value} when is_binary(Value) ->
	 		{value, binary_to_list(Value)};
		
	 	{Attribute, Value} ->
	 		{list, Value};
	 	{_, _} ->
	 		jsonCompare(Attribute, Tail)
	end.
