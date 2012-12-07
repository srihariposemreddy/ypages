-module(ypages_fbdata).

-export([fetchFBData/3, fbDataValidate/0, fetchFBHourlyData/1, compareHourlyData/1, fbRiakData/1, compareFBData/2]).

% fetch the FB Hourly Data 	

	fetchFBHourlyData(Url) ->
		FbResponse = ibrowse:send_req(Url, [], get, [], [{is_ssl,true},{ssl_options,[]}]),
	    StoreStatus = case FbResponse of 
		    		           {ok, "200", _, Response} -> 
		          			           RiakRes = compareHourlyData(Response),
		          			   		   if 
		          			   		      RiakRes == {success} ->
		          			   		   		{success, "", Url};
		          			   		   	  RiakRes == {id_not_found} ->
		          			   		   	  	{error, "Page Id not Found", Url};	
		          			   		   	  true ->
		          			   		   	    {error, "Riak Not Responding", Url}
		          			   		   end;
		          			   		   %yface_riak:fetchfbdata();
		          			   		   
		          			   {ok, "400", _, _} ->
		          			   		  {error, "Page Not Found", Url};
		          			   		  
		          			   {ok, _, _, _} ->
		          			   		  {error, "Server Not Responding", Url};
		          			   		  
		          			   {error, ErrData} ->
		          			           {error, ErrData, Url};
		          			           
		          			   {Any} ->
		          			   		   {error, Any, Url}
		              end,
		StoreStatus.
		
	compareHourlyData(Response) ->
	  
	  riakPID ! 
	  
	  RiakRes = yface_riak:storefbdata(Response).
		

fbmessage(Url) ->
	Url
	.

%% message to FB Data

fbDataValidate() ->
	io:format("request is ", []),
	receive 
		{Url, RequestPID, RiakPID} ->
			fetchFBData(Url, RequestPID, RiakPID)
	end,
		fbDataValidate().
	



% fetch the FB Daily Data 	

	fetchFBData(Url, RequestPID, RiakPID) ->
		
		%application:start(crypto),
		%application:start(ssl),
		ibrowse:start(),
		io:format("hello~n",[]),
		FbResponse = ibrowse:send_req(Url, [], get, [], [{is_ssl,true},{ssl_options,[]}]),
	    StoreStatus = case FbResponse of 
		    		           {ok, "200", _, Response} -> 
		    		           		  
		          			           %RiakRes = yface_riak:storefbdata(Response),
		          			           PageId = ypages_util:extract_json(["id"], Response),
		          			           {_, PD} = PageId,
		          			           io:format("ibrowse response id=~p  ~n",[PD]),
		          			   		   RiakPID ! {PD, Response},
		          			   		   %receive
		          			   		   	io:format("suuuuuuuu",[]); 
			          			   		  % if 
			          			   		  %    RiakRes == {success} ->
			          			   		  % 		RequestPID ! {success, "", Url};
			          			   		  % 	  RiakRes == {id_not_found} ->
			          			   		  % 	  	RequestPID ! {error, "Page Id not Found", Url};	
			          			   		   %	  true ->
			          			   		   %	    RequestPID ! {error, "Riak Not Responding", Url}
			          			   		   %end
		          			   		  % end;
		          			   		   %yface_riak:fetchfbdata();
		          			   		   
		          			   {ok, "400", _, _} ->
		          			   		  RequestPID ! {error, "Page Not Found", Url};
		          			   		  
		          			   {ok, _, _, _} ->
		          			   		  RequestPID ! {error, "Server Not Responding", Url};
		          			   		  
		          			   {error, ErrData} ->
		          			   		   io:format("Page on error: ~p ~n",[ErrData]),
		          			           RequestPID ! {error, ErrData, Url};
		          			           
		          			   { Any} ->
		          			   		  
		          			   		   RequestPID ! {error, Any, Url}
		              end,
		StoreStatus.
		
	fbRiakData(Response) ->
		
		case yface_util:extract_json("id", Response) of
            	{ok, ResponseId} ->
            		BucketName = yface_util:compare_bucket_name("20121126_Pages"),
					KeyName = yface_util:compare_key_bucket(ResponseId, "15"),
					RiakResponse = yface_riak:fetchfbdata(BucketName, KeyName),
					Test = case RiakResponse of
						{success, {ok, {_,_,_,_,[{_,Rres}],_,_}}  } ->
						  compareFBData(Rres, Response);
						Any ->
							Any
					end,
					io:format("hari testing ~p ~n",[Test])
					%exit("ending...")
		end.
		
	compareFBData(DbFbesponse, FbResponse) ->
		
		PrevData = mochijson2:decode(DbFbesponse),
		CurrData = mochijson2:decode(DbFbesponse).
