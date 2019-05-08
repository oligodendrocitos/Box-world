#const n=6.

%%%%%%%%%%%%%
%%% SORTS %%%
%%%%%%%%%%%%%

sorts

%% Things
#domain = {room, room2}.
#opening = {door}.
#box = {box1, box2, box3}.
#agent = {bot}.
#static_obj = {floor, door}. 
#thing = #box + #agent. 
#object = #box.
#surf = #box + {floor}.
%% Things that have a 3d location:. 
#obj_w_zloc = #thing + #static_obj.

%% Properties
#vertsz = 0..6. % units of length for Z for height and z location
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


           
%%%%%%%
% Other

holds(can_support(S, R),I) :- affordance_permits(go_to(R,S),I,ID).
-holds(can_support(S, R),I) :- affordance_forbids(go_to(R,S),I,11).
-holds(can_support(S, R),I) :- affordance_forbids(go_to(R,S),I,14).


% a structure can't support a agent if it's on something that can't support the agent
%holds(can_support(S,R,false),I) :- holds(on(S,S2),I),
%               					           affordance_forbids(go_to(R,S2),I,ID). % TODO add not aff_permits(;;) here

% CWA 
%-holds(can_support(S,R),I) :- not holds(can_support(S, R),I).

% only one of these is possible
%:- -holds(can_support(S, R),I), holds(can_support(S1,R),I), S=S1.


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
holds(in_range(OB0,OB1,X),I) :- holds(z_loc(OB0,Z0),I),
                                holds(z_loc(OB1,Z1),I),
                         	    height(OB0,H0), height(OB1, H1),
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

%-occurs(go_through(R,D,L2),I) :- not holds(in_range(D,R),I).


-occurs(go_to(R,S),I) :- affordance_forbids(go_to(R,S),I,ID).
-occurs(pick_up(R,O,S),T) :- affordance_forbids(pick_up(R,O,S),I,ID).
-occurs(move_to(R,O,S),T) :- affordance_forbids(move_to(R,S),I,ID).

% general affordance rules?
-occurs(A,I) :- affordance_forbids(A,I,ID).
%-occurs(A,I) :- not affordance_permits(A,ID). % this could be too restrictive
-occurs(pick_up(R,O),I) :- -affordance_permits(pick_up(R,O),I,ID).
-occurs(A,I) :- -affordance_permits(A,I,ID).

					   
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

%success :- goal(I),
%           I <= n. 
%:- not success.

% an action must occur at each step
%occurs(A,I) | -occurs(A,I) :- not goal(I).

% do not allow concurrent actions
:- occurs(A1, I),
   occurs(A2, I),
   A1!=A2.

% don't allow periods of inaction
%something_happened(I) :- occurs(A,I).

%:- not something_happened(I),
%   something_happened(I+1).

%:- goal(I), goal(I-1),
%   J < I,
%   not something_happened(J).

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

% agent can't pick up heavy objects TODO add human and smaller bot for agent specific affs. 
affordance_forbids(pick_up(R,O), I, 10) :- weight(O, heavy).
% A heavy agent can't be supported by a paper box
affordance_forbids(go_to(R,S), I, 11) :- weight(R,heavy), material(S,paper).
% A paper box can't support a heavy object
affordance_forbids(move_to(R,O,S), I, 12) :- weight(O,heavy), material(S,paper).
% Something can't be moved if it can't be picked up
affordance_forbids(move_to(R,O,S), I, 13) :- affordance_forbids(pick_up(R,O), I, ID).

% A agent can't go to a structure that cannot support it
affordance_forbids(go_to(R,S), I, 14) :- not holds(can_support(S, R),I), #object(S).

% affordance permits picking up things that are not heavy
affordance_permits(pick_up(R,O), I, 15) :- weight(O, light).
affordance_permits(pick_up(R,O), I, 16) :- weight(O, medium).

% affordance permits picking up objects that are in agents' range of reach. 
affordance_permits(pick_up(R,O), I, 17) :- height(R,H), height(O,HO),
																				   holds(in_range(O,R,X),I),
																					 X<H,
																					 X>=0.
% check if this will work if not forbid

% affordance permits moving objects that can be picked up
affordance_permits(move_to(R,O,S), I, 18) :- affordance_permits(pick_up(R,O), I, ID), 
					   														     not affordance_forbids(pick_up(R,O), I, ID).

% affordance permits going to objects that can support the agent
affordance_permits(go_to(R,S), I, 19) :- not affordance_forbids(go_to(R,S),I,11),
                                         not affordance_forbids(go_to(R,S),I,14).

% permits pick_up if there's a surface from which an object can be reached by the agent
affordance_permits(pick_up(R,O), I, 21) :- affordance_permits(go_to(R,S), I, ID),
					 											   				holds(in_range(S, O, X),I),
										  			 							height(R,H), height(S,HS), height(O,HO),
										 				  						X+HS>=0, X+HS<HO.
										  				   
										   
% permits go_through if there's a surface from which the exit can be reached by the agent AND it's possible for the agent to go to this surface      									  
affordance_permits(go_through(R,D,L), I, 22) :- affordance_permits(go_to(R,S), I, ID),
																								height(R,HR), height(D, HD), height(S,HS),
					                            					holds(in_range(S, D, X),I),
																								X+HS+HR>0, X+HS<=HD.


% BUT... this wouldn't demonstrate the capability that I need. 
% which is Permits(x), permits(y), permits(z)
% permits reach?
% However - this would need for me to add several things to the script where it actually worked in the first place.

% affordance permits going through the door if there are enough stackable objects in the domain that can support the robots weight?
% if there's a surface at the appropriate height that can support the agent
% if such a surface can be constructed. 
% permits pick up(R,O) :- permits(move(R, B, S)), permits(go_to(R,B)), adjusts_range(B, R, O) if on(B, S)
% I could add something that affords changing zloc - but that is implied in the fact that I can move it so how do I define it through this?
% the only way to get rid of what ifs is if I define permittances timelessy



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
%material(box2,paper).
material(box2,wood).
material(box3,wood).
material(floor,wood).


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

%goal(I) :- holds(z_loc(bot,5), I). % this should be impossible with two wooden and one paper box

%goal(I) :- holds(location(bot,room2), I). 
%goal(I) :- holds(in_hand(bot,box1), I). 
%goal(I) :- holds(on(box1, box2), I). 


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
display
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%occurs.
%goal.
%holds.
%-holds.
holds(can_support(A, B, C),I).
affordance_permits.
affordance_forbids.
 
 
 
 
 
 
