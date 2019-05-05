#const n=8.

%%%%%%%%%%%%%
%%% SORTS %%%
%%%%%%%%%%%%%

sorts

%% Things
#box = {box1, box2, box3, box4, box5}.
#robot = {apebot}.
#static_obj = {floor}. 
#thing = #box + #robot. 
#object = #box.
#surf = #box + #static_obj.
%% Things that have a 3d location:. 
#obj_w_zloc = #thing + #static_obj.

%% Properties
#vertsz = 0..7. % units of length for Z for height and z location
#mass = {light, medium, heavy}.
#materials = {paper, wood}.

%% Time and affordance indices
#step = 0..n.
#id = 10..20.
#bool = {true, false}.


%%%%%%%%%%%%%%%
%%% fluents %%%
%%%%%%%%%%%%%%%

%#inertial_fluent = on(#thing(X), #surf(Y)):X!=Y + z_loc(#obj_w_zloc(X), #vertsz) + in_hand(#robot, #object).

#inertial_fluent = on(#thing(X), #surf(Y)):X!=Y + in_hand(#robot, #object).

%#def_fluent = in_range(#obj_w_zloc, #robot).

#def_fluent = in_range(#obj_w_zloc, #robot) + z_loc(#obj_w_zloc(X), #vertsz).

#fluent = #inertial_fluent +#def_fluent.

%%%%%%%%%%%%%%%
%%% actions %%%
%%%%%%%%%%%%%%%

#action = go_to(#robot, #surf) + pick_up(#robot(X), #object(Y)) +
          move_to(#robot, #object(X), #surf(Y)):X!=Y.

%%%%%%%%%%%%%%%%%%
%%% PREDICATES %%%
%%%%%%%%%%%%%%%%%%
predicates

weight(#thing, #mass).
material(#box, #materials).
height(#obj_w_zloc, #vertsz).

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

% inertial z_location 
%holds(z_loc(R,H+L),I+1) :- occurs(go_to(R,S),I),
%                           height(O,H),
%                           holds(z_loc(S,L),I).

% move_to (X, Y), causes on(X, Y)
holds(on(O,S),I+1):- occurs(move_to(R,O,S),I).

% picking up results in holding the object
holds(in_hand(R,O),I+1) :- occurs(pick_up(R,O),I).

% move_to causes the object to be released
-holds(in_hand(R,O),I+1):- occurs(move_to(R,O,S),I).

                           

%%%%%%%%%%%%%%%%%%%
% State Constraints

% two things can't be at the same location, unless it's the floor
-holds(on(O,S),I) :- holds(on(O2,S),I),
                     #box(S),
                     O!=O2.

% ON defines 3dlocation
holds(z_loc(O,L+H),I) :- holds(on(O,S),I),
                         height(O,H),
                         holds(z_loc(S,L),I).


% z_loc defines whether in range
holds(in_range(O,R),T) :- holds(z_loc(O,LO),T),
                          holds(z_loc(R,LR),T),
                          height(R,H),
                          LO<=LR,
                          LO>=LR-H.
                          
% object can only be on one surface at a time
-holds(on(O, S), T) :- #thing(O), holds(on(O, S2), T), S!=S2.

% in_hand only possible for 1 object at a time (but this shouldn't be needed)
-holds(in_hand(R,O2),T) :- holds(in_hand(R,O1),T), O2!=O1.

% object properties have one value per object
-height(OZ,H2) :- height(OZ,H), H != H2.

%%%%%%%%%%%%%%%%%%%%%%%%%%
% Executability Conditions

% can only move 1 object at a time
%-occurs(move_to(R,O,S),T) :- occurs(move_to(R,O1,S),T),
%                             O1!=O.

% can't move to destinations out of reach
%-occurs(move_to(R,O,S),T) :- not holds(in_range(S,R),T).
% can't pick up objects out of reach
-occurs(pick_up(R,O),T) :- not holds(in_range(O,R),T).
-occurs(pick_up(R,O2),T) :- holds(in_hand(R,O),T).
-occurs(move_to(R,O,S),T) :- not holds(in_hand(R,O),T).

% don't go to the same place
-occurs(move_to(R,O,S),T) :- holds(on(O,S),T).
-occurs(go_to(R,S),T) :- holds(on(R,S),T).
-occurs(go_to(R,S),T) :- affordance_forbids(go_to(R,S),ID).
% affordance_forbids(pick_up(R,O), 10) :- weight(O, heavy).

% pick up not possible if something is on the object
-occurs(move_to(R,O,S),T) :- holds(on(O2, O), T).

% move/go_to not possible if something is on the box
-occurs(go_to(R,O),I) :- holds(on(O2, O), I),
                         #box(O).

-occurs(move_to(R,O2,O),I) :- holds(on(O1, O), I),
                              #box(O).

					   
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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%       
%%% History and initial state rules %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% action history
occurs(A,I) :- hpd(A,I).

%% Reality check
:- obs(F, true, I), -holds(F, I).
:- obs(F, false, I), holds(F, I).

holds(F,0) :- obs(F, B, 0).
-holds(F, 0) :- #inertial_fluent(F), not holds(F, 0).


%%%%%%%%%%%%%%%%%%%
%%% Affordances %%%
%%%%%%%%%%%%%%%%%%%

affordance_forbids(pick_up(R,O), 10) :- weight(O, heavy).
% affordance_forbids(pick_up(R,O), 11) :- not in_range(O,R). This needs a specific time
affordance_forbids(go_to(R,S), 11) :- weight(R,heavy), material(S,paper).
%affordance_forbids(move_to(R,O,S), 12) :- weight(O,heavy), material(S,paper).

%affordance_forbids going to x if x is on Y and affordance forbids go to y
affordance_forbids(go_to(R,S), 12) :- holds(on(S,X),I),affordance_forbids(go_to(R,X),ID).
% and another for the hierarchy?
% affordance_forbids going to x if affordance forbids going to x for the above reason?
%affordance_forbids(go_to(R,S), 13) :- ).

%affordance_permits(pick_up(R,O),13) :- 

%1. go to causes on by proxy?
%2. a box that inherits affordances of whatever it's on?



%%%%%%%%%%%%%%
%%% GROUND %%%
%%%%%%%%%%%%%%

weight(apebot, heavy).
weight(box1, light).
weight(box2, medium).
weight(box3, medium).
weight(box4, medium).
weight(box5, medium).

material(box1,paper).
material(box2,paper).
material(box3,wood).
material(box4,wood).
material(box5,wood).

height(apebot, 3).
height(floor, 0).
height(box1, 1). 
height(box2, 1). 
height(box3, 1).
height(box4, 1).
height(box5, 1).

holds(z_loc(floor,0),0).

holds(on(box1,box3),0). holds(on(box2,floor),0). holds(on(box3,floor),0). holds(on(box4,floor),0). 
holds(on(box5,floor),0).
holds(on(apebot, floor),0).

%goal(I) :- holds(in_hand(apebot, box2), I). 
%goal(I) :- holds(z_loc(box2,3), I). 
goal(I) :- holds(z_loc(apebot,5), I). 

%hpd(pick_up(apebot,box2),0).
%hpd(move_to(apebot,box2,box1),1).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
display
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
occurs.
goal.
holds.
%-holds.
%height.

 
 
 
 
 
