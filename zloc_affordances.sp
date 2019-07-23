%% --------------------------------------------
%% BW domain
%% An initial version of the BW domain with 
%% forbidding affordances which specify very  
%% basic agent / object criteria for a given 
%% action.
%% Includes a simple planning module.
%% 
%% Includes three actions : pick_up action 
%% produced some nonsensical actions, and
%% the design needs to be corrected. 
%% --------------------------------------------

#const n=4.

%%%%%%%%%%%%%
%%% SORTS %%%
%%%%%%%%%%%%%

sorts

%% Things
#domain = {room, room2}.
#opening = {door}.
#box = {box1, box2, box3}.
#robot = {bot}.
#static_obj = {floor, door}. 
#thing = #box + #robot. 
#object = #box.
#surf = #box + #static_obj.
%% Things that have a 3d location:. 
#obj_w_zloc = #thing + #static_obj.

%% Properties
#vertsz = 0..6. % units of length for Z for height and z location
#mass = {light, medium, heavy}.
#materials = {paper, wood}.

%% Time and affordance indices
#step = 0..n.
#id = 10..20.
#bool = {true, false}.

%%%%%%%%%%%%%%%
%%% fluents %%%
%%%%%%%%%%%%%%%

#inertial_fluent = on(#thing(X), #surf(Y)):X!=Y + z_loc(#obj_w_zloc, #vertsz) + location(#thing, #domain).

#def_fluent = in_range(#obj_w_zloc, #robot).

#fluent = #inertial_fluent +#def_fluent.

%%%%%%%%%%%%%%%
%%% actions %%%
%%%%%%%%%%%%%%%

#action = go_to(#robot, #surf) +
          move_to(#robot, #object(X), #surf(Y)):X!=Y+
          go_through(#robot, #opening, #domain). 

% go through includes the target location as it's currently the easiest way for me to specify locations without the door malarky



%%%%%%%%%%%%%%%%%%
%%% PREDICATES %%%
%%%%%%%%%%%%%%%%%%
predicates

% Properties
height(#obj_w_zloc, #vertsz).
weight(#thing, #mass).
material(#box, #materials).
has_exit(#domain, #opening).
% Affordance Predicate
can_support(#surf, #thing, #bool).


holds(#fluent, #step).
occurs(#action, #step).

% Planning Module Predicates
success().
goal(#step). 
something_happened(#step).

% Affordance Predicates
affordance_permits(#action, #id).
affordance_forbids(#action, #id).

% History Predicates
obs(#fluent, #bool, #step).
hpd(#action, #step).



%%%%%%%%%%%%%
%%% RULES %%%
%%%%%%%%%%%%%

rules
%%%%%%%%%%%%%
% Causal Laws

% go_to(X, Y) causes on(X, Y)
holds(on(R,S),I+1) :- occurs(go_to(R,S),I).

% move_to (X, Y), causes on(X, Y)
holds(on(O,S),I+1):- occurs(move_to(R,O,S),I).

% go_to causes z_loc to change
holds(z_loc(R,Z+H),I+1) :- occurs(go_to(R,S),I),
                           height(R,H),
                           holds(z_loc(S,Z),I).

% move_to causes z_loc to change
holds(z_loc(O,Z+H),I+1) :- occurs(move_to(R,O,S),I),
                           height(O,H),
                           holds(z_loc(S,Z),I).

% go_through the door causes the robot to be in room2.
holds(location(R,L),I+1) :- occurs(go_through(R,D,L),I).


           
%%%%%%%
% Other

can_support(S, R, true) :- not affordance_forbids(go_to(R,S),ID).


% a structure can't support a robot if it's on something that can't support the robot
can_support(S,R,false) :- holds(on(S,S2),I),
                          affordance_forbids(go_to(R,S2),ID).
         

%%%%%%%%%%%%%%%%%%%
% State Constraints

% two things can't be at the same location, unless this location is the floor
-holds(on(O,S),T) :- holds(on(O2,S),T),
                     #box(S),
                     O!=O2.

% Z coordinates are determined by an objects height and the location of the surface it is on
holds(z_loc(O,L+H),I) :- holds(on(O,S),I),
                         height(O,H),
                         holds(z_loc(S,L),I).


% Whether an object is in range is determined by agents' reach, location, and the objects' location
holds(in_range(O,R),I) :- holds(z_loc(O,LO),I),
                          holds(z_loc(R,LR),I),
                          height(R,H),
                          LO<=LR,
                          LO>=LR-H.
                          
% object can only be on one surface at a time
-holds(on(O, S), T) :- #thing(O), holds(on(O, S2), T), S!=S2.

% object properties have one value per object
-height(OZ,H2) :- height(OZ,H), H != H2.

% things can be in only one room at a time. This shouldn't be necessary. 
-holds(location(X,L),I) :- holds(location(X,L2),I), L!=L2.



%%%%%%%%%%%%%%%%%%%%%%%%%%
% Executability Conditions

% can only move 1 object at a time
-occurs(move_to(R,O,S),T) :- occurs(move_to(R,O1,S),T),
                             O1!=O.

% can't move objects which are out of reach
-occurs(move_to(R,O,S),T) :- not holds(in_range(O,R),T).


% Going to / moving to the current location results in nothing
-occurs(move_to(R,O,S),I) :- holds(on(O,S),I).
-occurs(go_to(R,S),I) :- holds(on(R,S),I).

% an object can't be moved if something's on top of it
-occurs(move_to(R,O,S),I) :- holds(on(O2, O), I).

% not possible to move/go_to an occupied location
-occurs(go_to(R,O),I) :- holds(on(O2, O), I),
                         #box(O).

% not possible to move/go_to an occupied location
-occurs(move_to(R,O,S),I) :- holds(on(O2, S), I),
                             #box(S).

% go_through possible only if the opening is in the room the robot is in, and in movement range
-occurs(go_through(R,D,L2),I) :- not holds(location(R,L1),I),
                                 not has_exit(L1,D),
                                 not has_exit(L2,D).

-occurs(go_through(R,D,L2),I) :- not holds(in_range(D,R),I).


-occurs(go_to(R,S),I) :- affordance_forbids(go_to(R,S),ID).
-occurs(move_to(R,O,S),T) :- affordance_forbids(move_to(R,O,S),ID).
%-occurs(go_to(R,S),T) :- not affordance_permits(go_to(R,S),ID).

% general affordance rules?
-occurs(A,I) :- affordance_forbids(A,ID).
%-occurs(A,I) :- not affordance_permits(A,ID).



					   
%%%%%%%%%%%%%%%%					   
% Inertia Axiom: 

holds(F, I+1) :- #inertial_fluent(F),
		holds(F, I),
		not -holds(F, I+1).

-holds(F, I2) :- #inertial_fluent(F),
		 -holds(F, I1),
		 not holds(F, I2),
		 I2 = I1 +1. 


% actions don't occur unless they definitely do
-occurs(A, I) :- not occurs(A, I).

% CWA
-holds(F,I) :- not holds(F,I), #def_fluent(F).


 
%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% GOALS AND PLANNING %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%

success :- goal(I),
           I <= n. 
:- not success.

% an action must occur at each step
occurs(A,I) | -occurs(A,I) :- not goal(I).

% do not allow concurrent actions
:- occurs(A1, I),
   occurs(A2, I),
   A1!=A2.

% don't allow periods of inaction
something_happened(I) :- occurs(A,I).

:- not something_happened(I),
   something_happened(I+1).

:- goal(I), goal(I-1),
   J < I,
   not something_happened(J).

%%%%%%%%%%%%%%%       
%%% History %%%
%%%%%%%%%%%%%%%

%% actions
occurs(A,I) :- hpd(A,I).

%% Reality check
:- obs(F, true, I), -holds(F, I).
:- obs(F, false, I), holds(F, I).

holds(F,0) :- obs(F, B, 0).
-holds(F, 0) :- #inertial_fluent(F), not holds(F, 0).



%%%%%%%%%%%%%%%%%%%
%%% Affordances %%%
%%%%%%%%%%%%%%%%%%%

% robot can't move heavy objects
affordance_forbids(move_to(R,O,S), 10) :- weight(O, heavy).
% A heavy robot can't be suppoerted by a paper box
affordance_forbids(go_to(R,S), 11) :- weight(R,heavy), material(S,paper).
% A paper box can't support a heavy object
affordance_forbids(move_to(R,O,S), 12) :- weight(O,heavy), material(S,paper).

% A robot can't go to a structure that cannot support it
affordance_forbids(go_to(R,S), 13) :- can_support(S, R, false).



%%%%%%%%%%%%%%
%%% GROUND %%%
%%%%%%%%%%%%%%

has_exit(room, door).
has_exit(room2, door).

weight(bot, heavy).
weight(box1, light).
weight(box2, medium).
weight(box3, medium).


material(box1,paper).
material(box2,wood).
material(box3,wood).


height(bot, 3).
height(floor, 0).
height(box1, 1). 
height(box2, 1). 
height(box3, 1).
height(door, 3).


% as floor is an independent object, just add this to make sure it's not causing trouble
holds(z_loc(floor,0),0).
holds(z_loc(floor,0),1).
holds(z_loc(floor,0),2).
holds(z_loc(floor,0),3).
holds(z_loc(door,5),0).

holds(on(box1,box3),0). holds(on(box2,floor),0). holds(on(box3,floor),0).
holds(on(bot, floor),0).

goal(I) :- holds(z_loc(bot,6), I). % this should be impossible with two wooden and one paper box
%goal(I) :- holds(location(bot,room2), I). 


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
display
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
occurs.
goal.
holds.
%-holds.
can_support.
 
 
 
 
 
 
