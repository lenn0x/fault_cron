-module(ft_cron_server).
-behaviour(gen_server).

%% API
-export([start_link/0, connect/1,recv_loop/1]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
         terminate/2, code_change/3]).

-define(SERVER, ?MODULE).
-define(LISTEN_PORT, 9000).
-define(TCP_OPTS, [binary, {packet, raw}, {nodelay, true}, {reuseaddr, true}, {active, once}]).

%%====================================================================
%% API
%%====================================================================
%%--------------------------------------------------------------------
%% Function: start_link() -> {ok,Pid} | ignore | {error,Error}
%% Description: Starts the server
%%--------------------------------------------------------------------
start_link() ->
  gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).
  
%%--------------------------------------------------------------------
%% Function: %% handle_call(Request, From, State) -> {reply, Reply, State} |
%%                                      {reply, Reply, State, Timeout} |
%%                                      {noreply, State} |
%%                                      {noreply, State, Timeout} |
%%                                      {stop, Reason, Reply, State} |
%%                                      {stop, Reason, State}
%% Description: Handling call messages
%%--------------------------------------------------------------------
handle_call(_Request, _From, State) ->
  Reply = ok,
  {reply, Reply, State}.

%%--------------------------------------------------------------------
%% Function: handle_cast(Msg, State) -> {noreply, State} |
%%                                      {noreply, State, Timeout} |
%%                                      {stop, Reason, State}
%% Description: Handling cast messages
%%--------------------------------------------------------------------
handle_cast(_Msg, State) ->
  {noreply, State}.

%%--------------------------------------------------------------------
%% Function: handle_info(Info, State) -> {noreply, State} |
%%                                       {noreply, State, Timeout} |
%%                                       {stop, Reason, State}
%% Description: Handling all non call/cast messages
%%--------------------------------------------------------------------
handle_info(_Info, State) ->
  {noreply, State}.

%%--------------------------------------------------------------------
%% Function: terminate(Reason, State) -> void()
%% Description: This function is called by a gen_server when it is about to
%% terminate. It should be the opposite of Module:init/1 and do any necessary
%% cleaning up. When it returns, the gen_server terminates with Reason.
%% The return value is ignored.
%%--------------------------------------------------------------------
terminate(_Reason, _State) ->
  ok.

%%--------------------------------------------------------------------
%% Func: code_change(OldVsn, State, Extra) -> {ok, NewState}
%% Description: Convert process state when code is changed
%%--------------------------------------------------------------------
code_change(_OldVsn, State, _Extra) ->
  {ok, State}.

%%--------------------------------------------------------------------
%%% Internal functions
%%--------------------------------------------------------------------

init([]) ->
  % start up the service and error out if we cannot
  case gen_tcp:listen(?LISTEN_PORT, ?TCP_OPTS) of
    {ok, Listen} -> 
    spawn(?MODULE, connect, [Listen]),
    io:format("~p Server Started.~n", [erlang:localtime()]);
    Error ->
      io:format("Error: ~p~n", [Error])
  end,
  {ok, []}.
  
connect(Listen) ->
    {ok, Socket} = gen_tcp:accept(Listen),
    inet:setopts(Socket, ?TCP_OPTS),
    % kick off another process to handle connections concurrently
    spawn(fun() -> connect(Listen) end),
    recv_loop(Socket),
    gen_tcp:close(Socket).

recv_loop(Socket) ->
    % reset the socket for flow control
    inet:setopts(Socket, [{active, once}]),
    receive
      % do something with the data you receive
      {tcp, Socket, Data} ->
          case Data of
              <<"is_ready\r\n">> ->
                  gen_tcp:send(Socket, "true");
              <<"quit\r\n">> -> ok;
              _ ->
                  gen_tcp:send(Socket, "I Received " ++ Data),
                  recv_loop(Socket)
          end;
        
        % exit loop if the client disconnects
        {tcp_closed, Socket} ->
          io:format("~p Client Disconnected.~n", [erlang:localtime()])
    end.