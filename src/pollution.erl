%%%-------------------------------------------------------------------
%%% @author Mateusz
%%% @copyright (C) 2019, <COMPANY>
%%% @docgetMaximumGradientStations/3
%%%
%%% @end
%%% Created : 06. kwi 2019 11:23
%%%-------------------------------------------------------------------
-module(pollution).
-author("Mateusz").

%% API
-export([createMonitor/0, getDate/1 , recordTest/0, addStation/3, addValue/5, removeValue/4, getOneValue/4, getStation/2, getStationMean/3, getDailyMean/3, getMaximumGradientStations/3, tests/0]).

-record(station, {name, coordinates}).
-record(measurement, {dateTime, type, value}).




createMonitor() -> dict:new().

addStation(Name, {Width, Height}, Monitor) ->
  K1 = getStationWithName(Name, Monitor),
  case K1 of
      false ->
        K2 = getStationWithCoordinates({Width, Height}, Monitor),
      case K2 of
        false -> dict:append_list(#station{name=Name, coordinates ={Width, Height}}, [],Monitor);
        _ -> {error, "station with that coordinates exists."}
      end;
    _ -> {error, "station with that name exists."}
  end.


%%Station moze byc coord abo name
getStationWithName(Station, Monitor)->
  Keys = dict:fetch_keys(Monitor),
  Key = [S || S <- Keys, string:equal(S#station.name,Station) or (S#station.coordinates == Station)],
  io:format(Key),
  case Key of
    [] -> false;
    _ -> [K] = Key,
      K
  end.

getStationWithCoordinates(Station, Monitor)->
  Keys = dict:fetch_keys(Monitor),
  Key = [S || S <- Keys, S#station.coordinates == Station],
  case Key of
    [] -> false;
    _ -> [K] = Key,
      K
  end.

%%addValue/5 - dodaje odczyt ze stacji (współrzędne geograficzne lub nazwa stacji, data, typ pomiaru, wartość),
%% zwraca zaktualizowany monitor; dziala
addValue(Station, DateTime, Type, Value, Monitor)->
  K1 = getStation(Station,Monitor),
  case K1 of
    false -> {error, "station with that name or coordinates does not exists."};
     _ ->
        Meas = dict:fetch(K1,Monitor),
        M1 = [M || M <-Meas, M#measurement.dateTime =:= DateTime, M#measurement.type=:=Type],
       M1,
        case M1 of
          [] -> dict:append(K1, #measurement{dateTime = DateTime,type = Type, value = Value}, Monitor);
          _ -> {error, "This measurement exists"}
        end
  end.


%%removeValue/4 - usuwa odczyt ze stacji (współrzędne geograficzne lub nazwa stacji, data, typ pomiaru),
%% zwraca zaktualizowany monitor;
removeValue(Station, Date, Type, Monitor)->
  K1 = getStation(Station, Monitor),
  case K1 of
    false -> {error, "station with that coordinates/name does not exists."};
    _ ->
      Meas = dict:fetch(K1,Monitor),
      Eq = fun(M) -> (getDate(M#measurement.dateTime) == Date) and (M#measurement.type == Type) end,
      case lists:any(Eq, Meas) of
        false -> {error, "This measurement does not exists"};
        true -> dict:update(K1, fun (M) -> [ X || X <- M, Eq(M) == false] end,  Monitor)
      end
  end.

getOneValue(Station, DateTime, Type, Monitor)->
  K1 = getStation(Station, Monitor),
  case K1 of
    false -> {error, "Station with that name/coordinates does not exist"};
    _ ->
      Val = [V || V<-dict:fetch(K1, Monitor), V#measurement.dateTime == DateTime, string:equal(V#measurement.type, Type)],
      case Val of
        [] -> {error, "No matching values"};
        _ -> [V] = Val,
              V#measurement.value
      end
  end.

getStationDailyMean({X,Y}, Date, Type, Monitor)->
  K1 = getStation({X,Y}, Monitor),
  case K1 of
    false -> -1;
    _-> Val = [V || V<-dict:fetch(K1,  Monitor), string:equal(V#measurement.type, Type), (getDate(V#measurement.dateTime) == Date)],
      case Val of
        [] -> -1;
        _ ->
          Res = getMeanValue(Val, 0, 0),
            Res
      end
end.

%%getStationMean/3 - zwraca średnią wartość parametru danego typu z zadanej stacji -DZIALA!!!!!!!!
getStationMean(Station, Type, Monitor)->
  K1 = getStation(Station, Monitor),
  case K1 of
    false -> {error, "not exists"};
    _->
      %%#station{measurement= M} = lists:filter(fun(#measurement{type = X}) -> X == Type end,
      Val = [V || V<-dict:fetch(K1,  Monitor), string:equal(V#measurement.type, Type)],
      case Val of
        [] -> {error, "No matching values"};
        _ ->
          Res = getMeanValue(Val, 0, 0),
            Res
      end
  end.

%%Dziala
getMeanValue([],_,0) -> 0;
getMeanValue([],Acc,Num) -> Acc/Num;
getMeanValue([#measurement{value = Value}|T],Acc,Num) ->getMeanValue(T,Acc+Value,Num+1).


%%getDailyMean/3 - zwraca średnią wartość parametru danego typu z danego dnai -DZIALA!!!!!!!!
getDailyMean(Type, Date, Monitor)->
  K = dict:fetch_keys(Monitor),
  case  K of
    false -> {error, "not exists"};
    _->
      Val = [V || K1 <- K, V<-dict:fetch(K1, Monitor), getDate(V#measurement.dateTime) == Date, V#measurement.type==Type],
      Val,
      case Val of
        [] -> {error, "No matching values"};
        _ ->
          Res = getMeanValue(Val, 0, 0),
          Res
      end
  end.

getDate(DateTime)->
  ({D, _}) = DateTime,
    D.


getStation(Station,Monitor) ->
  Keys = dict:fetch_keys(Monitor),
  Key = [S || S <- Keys, (S#station.name =:= Station)  or (S#station.coordinates =:= Station)],
  case Key of
    [] -> false;
    _ -> [K] = Key,
      K
  end.

%% 53. Dodaj do modułu pollution funkcję getMaximumGradientStations, która wyszuka parę stacji,
%% na których wystapił największy gradient zanieczyszczen w kontekście odległości.

getCoords(Monitor) ->
  Coords = [ K#station.coordinates ||  K<- dict:fetch_keys(Monitor) ],
  Coords.

list_max([]   ) -> {error,"empty"};
list_max([H|T]) -> list_max(H, T).

list_max(X, []   )            -> X;
list_max({_,_,V1}, [{C3,C4,V2}|T]) when V1 < V2 -> list_max({C3,C4,V2}, T);
list_max(X, [_|T]) -> list_max(X, T).

power(_,0) -> 1;
power(A,N) -> A*power(A,N-1).

getDistance({X1,Y1},{X2,Y2})->math:sqrt(power(X2-X1,2) + power(Y1-Y2,2)).

getMaximumGradientStations(Date, Type, Monitor)->
  List = [{{X,Y}, getStationDailyMean({X,Y}, Date, Type, Monitor)} || {X,Y} <-  getCoords(Monitor) ],

  ListOfValues = [ {Coords,Val} || {Coords,Val} <- List, Val /= -1],

  ListOfGradients = [ {{X1,Y1},{X2,Y2}, abs( (Val1 - Val2) / (getDistance({X1,Y1},{X2,Y2})))}
  || {{X1,Y1},Val1} <- ListOfValues, {{X2,Y2}, Val2} <- ListOfValues, {X1,Y1} /= {X2,Y2}],
  list_max(ListOfGradients).


recordTest()->
  S1 = #station{name = "S1", coordinates = {1,1}},
  io:format(S1#station.name).


tests()->
  P  = pollution:createMonitor(),
  P1 = pollution:addStation("a", {1,1}, P),
  P2 = pollution:addStation("b", {2,2}, P1),
  P3 = pollution:addStation("c", {5,5}, P2),
  P4 = pollution:addValue({1,1}, {{1999, 11, 30}, {10,00,00}},"PM10", 100, P3),
  P5 = pollution:addValue({2,2}, {{1999, 11, 30}, {12,00,00}},"PM10", 200, P4),
  P6 = pollution:addValue({5,5}, {{1999, 11, 30}, {20,00,00}},"PM10", 200, P5),
  P7 = pollution:addValue({5,5}, {{1999, 11, 30}, {21,00,00}},"PM10", 180, P6).
%%D1= pollution:getOneValue("b", {{1999,11,30}, {11,0,0}},"PM10", P7).
%%D= pollution:getOneValue("a", {{1999,11,30}, {11,0,0}},"PM10", P7).
%%C = pollution:getMaximumGradientStations({1999,11,30}, "PM10", P7).
%%B = pollution:getStationDailyMean({1,1}, {1999,11,30},"PM10" ,P7).
