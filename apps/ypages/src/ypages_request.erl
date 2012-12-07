-module(ypages_request).

-export([start/0, dailyLoop/1, hourlyLoop/1, fetchData/0]).

start() ->
	application:start(crypto),
    application:start(ssl),
    %appmon:start(),
	RiakPID = spawn(ypages_riak, store_data_to_riak, [self()]),
	
	receive 
		{ok, riak_is_up} ->
				io:format("Starting Pages Data .. ~n",[]),
				fetchData();
		
		{error, Reason} ->
				io:format("Riak is down, received: ~p ... ~n",[Reason])
			
	end.
	

fetchData() -> 
		
		Urls = ypages_urls:fb_daily_urls_list(),
		
		FbErrorUrlsList = dailyLoop(Urls),
		
		%Urls = ypages_urls:fb_hourly_urls_list(),
		
		%FbErrorUrlsList = hourlyLoop(Urls).
		
		io:format("Completed... ~p ",[FbErrorUrlsList]).
	
% Recursive for the Daily URL's List

 dailyLoop([]) ->
 		{"Successfully Pulled all URLS Daily Pages Data~n"};
 
 dailyLoop(ListOfUrls) ->
 		FBRequestPID = spawn(ypages_fbdata, fbDataValidate, []),
 		RiakPID = spawn(ypages_riak, store_data_to_riak, [self()]),
 		
 		ResultList = lists:map(fun(Url) -> 
 								  FBRequestPID ! {Url, self(),RiakPID}
 								  %exit("prs")
 		                          %receive
 		                          %	{error, Reason, UrlReturn} ->
 		                          %		{error, Reason, UrlReturn};
 		                          %	{success, _ ,UrlReturn} ->
 		                          %		{success, "", UrlReturn};
 		                          %	{Any} ->
 		                          %		io:format("Error in response", [])
 		                          %end
 		                       end, ListOfUrls),
		io:format(" Response = ~p ~n",[ResultList]),
 		RetryUrlsList = [ element(3, X) || X <- ResultList, element(1, X) == error ],
 		Len = length(RetryUrlsList),
 		if
 		   Len == 0 ->
 		       dailyLoop([]);
 		   true ->
 		       timer:sleep(60000),
 		       dailyLoop(RetryUrlsList)
 		end.	
	

% Recursive for the Hourly URL's List
		 	
 hourlyLoop([]) ->
 		{"Successfully Pulled all URLS Hourly Data~n"};
 					
 hourlyLoop(ListOfUrls) -> 
 		ResultList = lists:map(fun(Url) -> yface_fbdata:fetchFBHourlyData(Url) end, ListOfUrls),
 		
 		RetryUrlsList = [ element(3, X) || X <- ResultList, element(1, X) == error ],
 		Len = length(RetryUrlsList),
 		if
 		   Len == 0 ->
 		       hourlyLoop([]);
 		   true ->
 		       timer:sleep(60000),
 		       hourlyLoop(RetryUrlsList)
 		end.