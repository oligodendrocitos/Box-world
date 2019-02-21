#const n=3.

%%%%%%%%%%%%%
%%% SORTS %%%
%%%%%%%%%%%%%

sorts

%% Things
#box = {box1, box2, box3}.
#robot = {bot}.
#static_obj = {floor}. 
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

#inertial_fluent = on(#thing(X), #surf(Y)):X!=Y + z_loc(#obj_w_zloc(X), #vertsz).

#def_fluent = in_range(#obj_w_zloc, #robot).


#fluent = #inertial_fluent +#def_fluent.

%%%%%%%%%%%%%%%
%%% actions %%%
%%%%%%%%%%%%%%%

#action = go_to(#robot, #surf) +
          move_to(#robot, #object(X), #surf(Y)):X!=Y.



%%%%%%%%%%%%%%%%%%
%%% PREDICATES %%%
%%%%%%%%%%%%%%%%%%
predicates

% Properties
height(#obj_w_zloc, #vertsz).
weight(#thing, #mass).
material(#box, #materials).
% Affordance Predicate
can_support(#surf, #thing).


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
           
%%%%%%%
% Other

can_support(S, R) :- holds(on(S,X),I), not affordance_forbids(go_to(R,X),ID).
         

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

-occurs(go_to(R,S),T) :- affordance_forbids(go_to(R,S),ID).
%-occurs(move_to(R,O,S),T) :- affordance_forbids(move_to(R,O,S),ID).

					   
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

%affordance_forbids going to x if x is on Y and affordance forbids go to y
affordance_forbids(go_to(R,S), 13) :- holds(on(S,X),I),affordance_forbids(go_to(R,X),ID).

% Alternatively, using a predicate can_support
% affordance_permits(go_to(R,S), 13) :- can_support(S, R).
% Which is defined by the rule:
% can_support(S, R) :- holds(on(S,X),I), not affordance_forbids(go_to(R,X),ID).


%%%%%%%%%%%%%%
%%% GROUND %%%
%%%%%%%%%%%%%%

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


% as floor is an independent object, just add this to make sure it's not causing trouble
holds(z_loc(floor,0),0).
holds(z_loc(floor,0),1).
holds(z_loc(floor,0),2).
holds(z_loc(floor,0),3).

holds(on(box1,box3),0). holds(on(box2,floor),0). holds(on(box3,floor),0).
holds(on(bot, floor),0).

goal(I) :- holds(z_loc(bot,5), I). 


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
display
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
occurs.
goal.
holds.
%-holds.
 
 
 
 
 
 
