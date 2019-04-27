%%%-------------------------------------------------------------------
%%% @author Mateusz
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 26. kwi 2019 18:42
%%%-------------------------------------------------------------------
-module(pollution_server).
-author("Mateusz").

%% API
-export([init/0]).
-export([start/0, stop/0]).
-export([addStation/2,addValue/4,removeValue/3,getOneValue/3,getStationMean/3,getDailyMean/2, getMaximumGradientStations/2]).


start()->
  register (pollutionServer, spawn(pollution_server, init, [])).

stop()->
  pollutionServer ! stop.


init()->
  loop(pollution:createMonitor()).


loop(Monitor)->
  receive
    {request, Pid, addStation, {Name, {Width, Height}}}->
      NewMonitor = pollution:addStation(Name, {Width, Height}, Monitor),
      case NewMonitor of
        {error, ErrMsg} -> Pid ! {reply, ErrMsg}, loop(Monitor);
        _ -> Pid ! {reply, ok}, loop(NewMonitor)
      end;

    {request, Pid, addValue, {Station, DateTime, Type, Value}}->
      NewMonitor = pollution:addValue(Station, DateTime, Type, Value , Monitor),
      case NewMonitor of
        {error, ErrMsg} -> Pid ! {reply, ErrMsg}, loop(Monitor);
        _ -> Pid ! {reply, ok}, loop(NewMonitor)
      end;

    {request, Pid, removeValue, {Station, Date, Type}}->
      NewMonitor = pollution:removeValue(Station, Date, Type,Monitor),
      case NewMonitor of
        {error, ErrMsg} -> Pid ! {reply, ErrMsg}, loop(Monitor);
        _ -> Pid ! {reply, ok}, loop(NewMonitor)
      end;

    {request, Pid, getOneValue, {Station, DateTime, Type}} ->
      NewMonitor = pollution:getOneValue(Station, DateTime, Type,Monitor),
      case NewMonitor of
        {error, ErrMsg} -> Pid ! {reply, ErrMsg}, loop(Monitor);
        _ -> Pid ! {reply, ok}, loop(NewMonitor)
      end;

    {request, Pid, getStationMean, {{X,Y}, Date, Type}}->
      NewMonitor = pollution:getStationMean({X,Y}, Date, Type,Monitor),
      case NewMonitor of
        {error, ErrMsg} -> Pid ! {reply, ErrMsg}, loop(Monitor);
        _ -> Pid ! {reply, ok}, loop(NewMonitor)
      end;

    {request, Pid, getDailyMean, {Type, Date}}->
      NewMonitor = pollution:getStationMean(Type, Date,Monitor),
      case NewMonitor of
        {error, ErrMsg} -> Pid ! {reply, ErrMsg}, loop(Monitor);
        _ -> Pid ! {reply, ok}, loop(NewMonitor)
      end;

    {request, Pid, getMaximumGradientStations, {Date, Type}}->
      NewMonitor = pollution:getMaximumGradientStations(Date, Type, Monitor),
      case NewMonitor of
        {error, ErrMsg} -> Pid ! {reply, ErrMsg}, loop(Monitor);
        _ -> Pid ! {reply, ok}, loop(NewMonitor)
      end;

    stop -> ok


  end.


call(Message, Parameters) ->
  pollutionServer ! {request, self(), Message, Parameters},
  receive
    {reply, Reply} -> Reply
  end.
addStation(Name, {Width, Height}) -> call(addStation,{Name, {Width, Height}}).
addValue(Station, DateTime, Type, Value) -> call(addValue, {Station, DateTime, Type, Value}).
removeValue(Station, Date, Type) -> call(removeValue, {Station, Date, Type}).
getOneValue(Station, DateTime, Type) -> call(getOneValue, {Station, DateTime, Type}).
getStationMean({X,Y}, Date, Type) -> call(getStationMean, {{X,Y}, Date, Type}).
getDailyMean(Type, Date) -> call(getDailyMean, {Type, Date}).
getMaximumGradientStations(Date, Type) -> call(getMaximumGradientStations, {Date, Type}).

