-module(chatserver).
-export([start/1, rotate_log/0]).
-export([init/1, par_connect/3, init_loop/0]).
-include("File.hrl").

start(Port) -> register(?MODULE, spawn(?MODULE, init, [Port])).

init(Port) ->
  LogFileName = atom_to_list(?MODULE) ++ ".log",
  disk_log:open([{name, chatserver_log}, 
                 {format, external}, 
                 {file, LogFileName}]),
  Room2Chatter = ets:new(room2Chatter, [public, named_table]),
  Chatter2Room = ets:new(chatter2Room, [public, named_table]),
  {ok, LSocket} = gen_tcp:listen(Port, [{packet, 0},
                                        {reuseaddr, true},
                                        {active, once}]),
  spawn(?MODULE, par_connect, [LSocket, Room2Chatter, Chatter2Room]),
  init_loop().

rotate_log() -> ?MODULE ! log_rotate.

init_loop() ->
  receive
    log_rotate ->
      {{Year,Month,Day},{Hour,Min,Sec}} = erlang:localtime(),
      Ds = io_lib:format("~4.10.0B~2.10.0B~2.10.0B_~2.10.0B~2.10.0B~2.10.0B", 
                         [Year, Month, Day, Hour, Min, Sec]),
      LogFileName = atom_to_list(?MODULE) ++ Ds ++ ".log",
      disk_log:breopen(chatserver_log, LogFileName, <<>>),
      ?MODULE:init_loop()
  end.

par_connect(LSocket, Room2Chatter, Chatter2Room) ->
  {ok, Socket} = gen_tcp:accept(LSocket),
  spawn(?MODULE, par_connect, [LSocket, Room2Chatter, Chatter2Room]),
  loop(zero, #chatserver_state{sock=Socket, 
                               rc=Room2Chatter, 
                               cr=Chatter2Room, 
                               name=void}).

loop(Buff, State) ->
  receive
    {tcp, Socket, Data} -> 
      Socket = State#chatserver_state.sock,
      inet:setopts(Socket, [{active, once}]),
      handle_data(Buff, Data, State);
    {tcp_closed, Socket} -> 
      Socket = State#chatserver_state.sock,
      process_input(leave_room, State);
    {send, Data} -> 
      gen_tcp:send(State#chatserver_state.sock, [0, Data, 255]),
      loop(Buff, State)
  end.

handle_data(zero, [0|T], State) ->
  handle_data([], T, State);
handle_data(zero, [], State) ->
  loop(zero, State);
handle_data(L, [255|T], State) ->
  Line = lists:reverse(L),
  State1 = parse_input(State, list_to_binary(Line)),
  handle_data(zero, T, State1);
handle_data(L, [H|T], State) ->
  handle_data([H|L], T, State);
handle_data(L, [], State) ->
  loop(L, State).

parse_input(State, Bin) ->
  <<Method:8, RoomLenB:4/binary, Rest/binary>> = Bin,
  RoomLen = list_to_integer(binary_to_list(RoomLenB)),
  <<Room:RoomLen/binary, NameLenB:4/binary, Rest1/binary>> = Rest,
  NameLen = list_to_integer(binary_to_list(NameLenB)),
  <<Name:NameLen/binary, Msg/binary>> = Rest1,
  State1 = case State#chatserver_state.name of
             void -> State#chatserver_state{name=Name};
             _ -> State
           end,
  case Method of
    1 -> process_input(enter_room, Room, State1);
    2 -> process_input(leave_room, State1);
    3 -> process_input(speak, Msg, State1)
  end.

process_input(enter_room, Room, #chatserver_state{sock=Socket, 
                                                  rc=Room2Chatter,
                                                  cr=Chatter2Room,
                                                  name=Name} = State) ->
  NotInAnyRoom = case {ets:lookup(Chatter2Room, Name), 
                       ets:lookup(Room2Chatter, Room)} of
                   {[], []} -> Chatters = [], true;
                   {[], [{Room, Chatters}]} -> true;
                   {[{Name, AnotherRoom}], _} -> 
                     Chatters = [],
                     gen_tcp:send(Socket,["You're already in room", AnotherRoom]),
                     false
                 end,
  case NotInAnyRoom of
    false -> ok;
    true ->
      ets:insert(Room2Chatter, {Room, NewChatters = [self() | Chatters]}),
      [Pid ! {send, [Name, " has entered this room."]} || Pid <- NewChatters],
      ets:insert(Chatter2Room, {Name, Room})
  end,
  State;
process_input(speak, Msg, #chatserver_state{sock=Socket,
                                            rc=Room2Chatter,
                                            cr=Chatter2Room,
                                            name=Name} = State) ->
  case ets:lookup(Chatter2Room, Name) of
    [] -> gen_tcp:send(Socket, ["You're not in any room."]);
    [{Name, Room}] -> 
      {{Year,Month,Day},{Hour,Min,Sec}} = erlang:localtime(),
      Ds = io_lib:format("~4.10.0B-~2.10.0B-~2.10.0B ~2.10.0B:~2.10.0B:~2.10.0B",
                         [Year, Month, Day, Hour, Min, Sec]),
      disk_log:blog(chatserver_log, [Ds, 1, Room, 1, Name, 1, Msg, 10]),
      [Pid ! {send, [Name, ": ", Msg]} || Pid <- element(2, hd(ets:lookup(Room2Chatter, Room)))]
  end,
  State.
process_input(leave_room, #chatserver_state{sock=Socket,
                                            rc=Room2Chatter,
                                            cr=Chatter2Room,
                                            name=Name} = State) ->
  case ets:lookup(Chatter2Room, Name) of
    [] -> gen_tcp:send(Socket, ["You're not in any room."]);
    [{Name, Room}] ->
      [{Room, OriChats}] = ets:lookup(Room2Chatter, Room),
      case Chats = lists:delete(self(), OriChats) of
        [] -> ets:delete(Room2Chatter, Room);
        _  -> ets:insert(Room2Chatter, {Room, Chats})
      end,
      ets:delete(Chatter2Room, Name),
      [Pid ! {send, [Name, " has left this room."]} || Pid <- OriChats]
  end,
  State.
