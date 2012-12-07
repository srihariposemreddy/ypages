-module(ypages_riak).

-export([store_data_to_riak/1, fetch_data_from_riak/2, handle_riak_messages/2]).

-include("include/yface_init.hrl").

  
   
% Stores the FB Data to Riak Server
% Request String format
% Response {status, message}
	store_data_to_riak(ParentPid) ->
		RiakResponse = riakc_pb_socket:start_link(?RIAK_HOST, ?RIAK_PORT),
		
        case RiakResponse of 
			{ok, Pid} ->
			    ParentPid ! {ok, riak_is_up},
				handle_riak_messages(Pid, ParentPid);
				
			Any ->
				ParentPid ! {error, "Riak Not Responding"}	
		end.


    handle_riak_messages(Pid, ParentPid) -> 
    	io:format("riak response waiting ",[]),
		receive
			{PageId, Response} ->
				io:format("riak response --  ~p ",[PageId]),
				ResponseBinary = list_to_binary(Response),
				Object = riakc_obj:new(ypages_util: current_bucket_name(), ypages_util:current_key_bucket(PageId), ResponseBinary, "application/x-erlang-binary"),
				riakc_pb_socket:put(Pid, Object),
				ParentPid ! {ok, success},
				handle_riak_messages(Pid, ParentPid);
			
			quit ->
			    ParentPid ! done,
			    true;
			
			Any ->
			    ParentPid ! {error, bad_riak_message},
			    handle_riak_messages(Pid, ParentPid) 
		
		end.
				
			
% Fetch data from riak
	  fetch_data_from_riak(BucketName, KeyName) ->
	  			RiakResponse = riakc_pb_socket:start_link(?RIAK_HOST, ?RIAK_PORT),

			case RiakResponse of
				{ok, Pid}  ->
					%ResponseBinary = list_to_binary(Response),
					Object = riakc_pb_socket:get(Pid, BucketName, KeyName),
					{success, Object};
				{_, _}  ->
					io:format("Riak is Not Responding"),
					{error, "Riak is not Responding"}
			end.			
