#const n=6.

%%%%%%%%%%%%%
%%% SORTS %%%
%%%%%%%%%%%%%

sorts

%% Things
#domain = {room, room2}.
#opening = {door}.
#box = {box1, box2, box3}.
#agent = {robot, human}.
#static_obj = {floor, door}. 
#thing = #box + #agent. 
#object = #box.
#surf = #box + {floor}.
%% Things that have a 3d location:. 
#obj_w_zloc = #thing + #static_obj.

%% Properties
#vertsz = 0..18. % units of length for Z for height and z location
#mass = {light, medium, heavy}.
#materials = {paper, wood}.

%% Time and affordance indices
#step = 0..n.
#id = 10..30.
#bool = {true, false}.

%%%%%%%%%%%%%%%
%%% fluents %%%
%%%%%%%%%%%%%%%

#inertial_fluent = on(#thing(X), #surf(Y)):X!=Y + z_loc(#obj_w_zloc, #vertsz) + location(#thing, #domain) + in_hand(#agent, #object).

#def_fluent = in_range(#obj_w_zloc, #obj_w_zloc, #vertsz) + can_support(#surf, #thing).

#fluent = #inertial_fluent +#def_fluent.

%%%%%%%%%%%%%%%
%%% actions %%%
%%%%%%%%%%%%%%%

#action = go_to(#agent, #surf) +
          move_to(#agent, #object(X), #surf(Y)):X!=Y+
          go_through(#agent, #opening, #domain) +
          pick_up(#agent, #object). 

% go through includes the target location as it's the easiest way for me to specify this action without additional changes



%%%%%%%%%%%%%%%%%%
%%% PREDICATES %%%
%%%%%%%%%%%%%%%%%%
predicates

% Properties
height(#obj_w_zloc, #vertsz).
weight(#thing, #mass).
material(#surf, #materials).
has_exit(#domain, #opening).


% Affordance Predicate
holds(#fluent, #step).
occurs(#action, #step).

% Planning Module Predicates
success().
goal(#step). 
something_happened(#step).

% Affordance Predicates
affordance_permits(#action, #step, #id).
affordance_forbids(#action, #step, #id).

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

% move_to causes the moved object to be released
-holds(in_hand(R,O),I+1):- occurs(move_to(R,O,S),I).

% go_to causes z_loc to change
holds(z_loc(R,Z+H),I+1) :- occurs(go_to(R,S),I),
                           height(R,H),
                           holds(z_loc(S,Z),I).

% move_to causes z_loc to change
holds(z_loc(O,Z+H),I+1) :- occurs(move_to(R,O,S),I),
                           height(O,H),
                           holds(z_loc(S,Z),I).

% go_through the door causes the agent to be in room2.
holds(location(R,L),I+1) :- occurs(go_through(R,D,L),I).

% pick_up causes in_hand 
holds(in_hand(R,O), I+1) :- occurs(pick_up(R,O),I).

% pick_up negates an objects location.
-holds(on(O,S),I+1) :- occurs(pick_up(R,O),I), 
                       holds(on(O,S),I). 

-holds(z_loc(O,Z),I+1) :- occurs(pick_up(R,O),I), 
                          holds(z_loc(O,Z),I). 

% go_to causes an agent to change its location
-holds(on(A,S),I+1) :- occurs(go_to(A,S2),I), 
                       holds(on(A,S),I).

% moving causes z coordinates to change 
-holds(z_loc(R,Z),I+1) :- occurs(go_to(R,S),I),
                          holds(z_loc(R,Z),I).
% !! This may cause an issue if moving to a place on the same height as before. This should be a defined fluent.



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


% In range specifies location of one object w.r.t. another
% Range is a number (of sort #vertsz). Numbers in .sp must be non-negative,
% so OB0 must be higher, or on the same level as OB1.
% X therefore denotes how much higher the base of OB0 is 
% w.r.t. the base of OB1. 
% For example, if OB0 and OB1 are on the same surface, X=0;
% if OB0 is on a surface 1 unit higher than the bottom surface of OB1, X=1.
% The bottom surface is used because objects and agents have varying height.
% Using z_loc (top surface coordinates) would require more arithmetic when 
% defining action capabilities of specific agents. 
holds(in_range(OB0,OB1,X),I) :- holds(z_loc(OB0,Z0),I),
                                holds(z_loc(OB1,Z1),I),
																height(OB0,H0), height(OB1, H1),
																(Z0-H0)>=(Z1-H1),
                       	        X = (Z0-H0)-(Z1-H1).
                          
% object can only be on one surface at a time
-holds(on(O, S), T) :- #thing(O), holds(on(O, S2), T), S!=S2.

% object properties have one value per object
-height(OZ,H2) :- height(OZ,H), H != H2.

% things can be in only one room at a time. This shouldn't be necessary. 
-holds(location(X,L),I) :- holds(location(X,L2),I), L!=L2.

% can only hold 1 object at a time
-occurs(move_to(R,O,S),T) :- occurs(move_to(R,O1,S),T),
                             O1!=O.

%%%%%%%%%%%%%%%%%%%%%%%%%%
% Executability Conditions

% can only pick up 1 object at a time
-occurs(pick_up(R,O),I) :- holds(in_hand(R,O1),I),
                           O1!=O.

-occurs(pick_up(R,O),I) :- holds(in_hand(R,O),I).

% can't pick up objects which are out of reach
%-occurs(pick_up(R,O),I) :- not holds(in_range(O,R),I).

% can't move object not currently holding
-occurs(move_to(R,O,S),I) :- not holds(in_hand(R,O),I).

% Going to / moving to the current location results in nothing
%-occurs(move_to(R,O,S),I) :- holds(on(O,S),I).
-occurs(go_to(R,S),I) :- holds(on(R,S),I).

% agent cannot go on top of an object it's currently holding
-occurs(go_to(R,B),I) :- holds(in_hand(R,B),I).

% an object can't be picked_up if something's on top of it
-occurs(pick_up(R,O),I) :- holds(on(O2, O), I).

% not possible to move/go_to an occupied location
-occurs(go_to(R,O),I) :- holds(on(O2, O), I),
                         #box(O).

% not possible to move/go_to an occupied location
-occurs(move_to(R,O,S),I) :- holds(on(O2, S), I),
                             #box(S).

% go_through possible only if the opening is in the room the agent is in, and in movement range
-occurs(go_through(R,D,L2),I) :- not holds(location(R,L1),I),	
                                 not has_exit(L1,D),
                                 not has_exit(L2,D).


% Affordance rules:


holds(can_support(S, R),I) :- affordance_permits(go_to(R,S),I,ID).
-holds(can_support(S, R),I) :- affordance_forbids(go_to(R,S),I,11).
-holds(can_support(S, R),I) :- affordance_forbids(go_to(R,S),I,14).


% a structure can't support a agent if it's on something that can't support the agent
-holds(can_support(S,R),I) :- holds(on(S,S2),I),
               					      affordance_forbids(go_to(R,S2),I,ID). % TODO add not aff_permits(;;) here

% CWA 
%-holds(can_support(S,R),I) :- not holds(can_support(S, R),I).

% only one of these is possible
%:- -holds(can_support(S, R),I), holds(can_support(S1,R),I), S=S1.

-occurs(go_to(R,S),I) :- affordance_forbids(go_to(R,S),I, 14).
-occurs(pick_up(R,O,S),T) :- affordance_forbids(pick_up(R,O,S),I,ID).
-occurs(move_to(R,O,S),T) :- affordance_forbids(move_to(R,S),I, 13).

% general affordance rules?
-occurs(A,I) :- affordance_forbids(A,I,ID).
%-occurs(A,I) :- not affordance_permits(A,I,ID). % this could be too restrictive
-occurs(pick_up(R,O),I) :- not affordance_permits(pick_up(R,O),I,17).
-occurs(move_to(A,O,S),I) :- not affordance_permits(move_to(A,O,S),I, 19).
-occurs(go_to(A,S),I) :- not affordance_permits(go_to(A,S),I,22).
%-occurs(A,I) :- -affordance_permits(A,I,ID).
-occurs(go_through(A,D,R),I) :- not affordance_permits(go_through(A,D,R),I,25).

					   
%%%%%%%%%%%%%%%%					   
% Inertia Axiom: 

holds(F, I+1) :- #inertial_fluent(F),
		holds(F, I),
		not -holds(F, I+1).

-holds(F, I+1) :- #inertial_fluent(F),
		 -holds(F, I),
		 not holds(F, I+1). 


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

% TODO: strange stuff happening with can support. Inspect the fluent, the rules, the affordances (NB. both!!)

% Add: 
% Medium heavy agent can't be supported by paper objects, 
% Light agent can be supported by cardboard objects
% Strength: Strong agents can lift heavy objects
% Perhaps, human agents can lift things that are a bit below them, whereas a bor can't. 
% a roomba or some agent without arms can't lift at all. 

% agent can't pick up heavy objects TODO add human and smaller bot for agent specific affs. 
affordance_forbids(pick_up(R,O), I, 10) :- weight(O, heavy).
% A heavy agent can't be supported by a paper box
affordance_forbids(go_to(R,S), I, 11) :- weight(R,heavy), material(S,paper).
% A paper box can't support a heavy object
affordance_forbids(move_to(R,O,S), I, 12) :- weight(O,heavy), material(S,paper).

% Exec. Cond. 
% Something can't be moved if it can't be picked up
affordance_forbids(move_to(R,O,S), I, 13) :- affordance_forbids(pick_up(R,O), I, ID).

% Exec. Cond. 
% A agent can't go to a structure that cannot support it
affordance_forbids(go_to(R,S), I, 14) :- not holds(can_support(S, R),I), #object(S).

% affordance permits picking up things that are not heavy for the agent. 
affordance_permits(pick_up(R,O), I, 15) :- weight(O, light).
affordance_permits(pick_up(R,O), I, 16) :- weight(O, medium).


% Exec. Cond. 
% affordance permits picking up objects that are in agents' range of reach. 
% if X=0, object is at agents' 'feet'; 
% if X=H (agents' height), the object is above the agent (and thus can't be picked up).
affordance_permits(pick_up(R,O), I, 17) :- height(R,H), height(O,HO),
																				   holds(in_range(O,R,X),I),
																					 X<H,
																					 X>=0.
% check if this will work if not forbid


% General Case
% affordance permits moving objects that can be picked up.
affordance_permits(move_to(R,O,S), I, 18) :- affordance_permits(pick_up(R,O), I, 15), 
																						 affordance_permits(pick_up(R,O), I, 16),
																						 not affordance_forbids(move_to(R,O,S), I, 12).

% Exec. Cond.
% affordance permits moving objects that can be picked up and are in range. 
affordance_permits(move_to(R,O,S), I, 19) :- affordance_permits(pick_up(R,O), I, ID), 
					   														     not affordance_forbids(pick_up(R,O), I, ID), 
																						 not affordance_forbids(move_to(R,O,S),I, 12).

% General Case
% affordance permits going to objects that can support the agent
affordance_permits(go_to(R,S), I, 20) :- not affordance_forbids(go_to(R,S),I,11).

% General Case
% affordance permits to go to some surface if you move it on top of something that you can also stand on.
affordance_permits(go_to(A,S),I, 21) :- affordance_permits(go_to(A,Y),I, 20),
																		    affordance_permits(move_to(A,S,Y),I, 18).
																		

% Exec. Cond. 
% affordance permits going to objects that can support the agent and are not on top of something that doesn't. 
affordance_permits(go_to(R,S), I, 22) :- not affordance_forbids(go_to(R,S),I,11),
                                         not affordance_forbids(go_to(R,S),I,14).

% General Case
% permits pick_up if there's a surface from which an object can be reached by the agent:
% if X=0, the base of the object starts at the same level as the surface. 
% in this case 
% if X-height(surf)=0, the object would be at agents' 'feet'.
% if X-height(surf)>=height(agent), then the object would be above the agent.  
affordance_permits(pick_up(R,O), I, 23) :- affordance_permits(go_to(R,S), I, ID),
					 											   				 holds(in_range(O, S, X),I),
										  			 							 height(R,H), height(S,HS), height(O,HO),
										 				  						 X>=0+HS,
																					 X<H+HS.
% N.B.: there's an executability condition in the head of the above rule (ID includes 21 & 22). 
% I'm not sure whether it would work result in nonsense if this is changed to the general case. 
										  				   

% General Case										   
% permits go_through if there's a surface from which the exit can be reached by the agent 
% AND it's possible for the agent to go to this surface.
% Height of surf and agent need to be at least X, otherwise the door is above the agent;
% Height of surf needs to be smaller than X and the object height, otherwise the door is below the agent.
% This is used as an affordance (general case)
% TODO: add in a move to, or add a second case where no surf. exists, but the agent moves it, and make that as one of the conditions for the general case. 
affordance_permits(go_through(R,D,L), I, 24) :- affordance_permits(go_to(R,S), I, ID),
																								height(R,HR), height(D, HD), height(S,HS),
					                            					holds(in_range(D, S, X),I),
																								HS+HR>X,
																								HS<X+HD.

% Exec. Cond. 
% permits go through if door is within agents' reach
% Statements as above. 
affordance_permits(go_through(R,D,L), I, 25) :- holds(on(R,S),I),
																								height(R,HR), height(D, HD), height(S,HS),
					                            					holds(in_range(D, S, X),I),
																								HS+HR>X,
																								HS<X+HD.




%%%%%%%%%%%%%%
%%% GROUND %%%
%%%%%%%%%%%%%%

has_exit(room, door).
has_exit(room2, door).

weight(robot, heavy).
weight(human, heavy).
weight(box1, light).
weight(box2, medium).
weight(box3, medium).


material(box1,paper).
%material(box2,paper).
material(box2,wood).
material(box3,wood).
material(floor,wood).


height(robot, 2).
height(human, 3).
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
holds(z_loc(door,7),0).

holds(on(box1,box3),0). holds(on(box2,floor),0). holds(on(box3,floor),0).
holds(on(robot, floor),0).
holds(location(robot, room),0).

%goal(I) :- holds(z_loc(robot,5), I). % this should be impossible with two wooden and one paper box if bot height is 2

%goal(I) :- holds(location(robot,room2), I), holds(location(human, room2),I). 
goal(I) :- holds(location(human, room2),I). 
%goal(I) :- holds(location(robot,room2), I). 
%goal(I) :- holds(in_hand(robot,box1), I). 
%goal(I) :- holds(on(box1, box2), I). 


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
display
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
occurs.
goal.
holds.
%-holds.
affordance_permits.
affordance_forbids.
 
 
 
 
 
 
