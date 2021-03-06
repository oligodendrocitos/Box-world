%% --------------------------------------------
%% Domain initial condition generation. 
%%
%% This script generates answer sets consisting of 
%% initial conditions for a particular domain, to 
%% be used for random initial condition selection. 
%% State constraints are applied, so as to yield
%% valid configurations e.g.: fluent on(X, Y) may
%% only contain compatible objects. 
%% 
%% --------------------------------------------


#const n=0.

sorts

#area = {room, corridor}.
#exit = {door, window}.


#agent = {robot}.
#fixed_element = {floor, floor_cor} + #exit.
#object = {box1, box2, box3, box4, box5, chair, cup}.
#thing = #object + #agent.

#obj_w_zloc = #thing + #fixed_element.


#vertsz = 0..15.
#step = 0..n.
#id = 10..30.
#bool = {true, false}.

%% VARIABLE PARAMETERS
#substance = {paper, plastic, wood, glass}.
#weight = {light, medium, heavy}.

#skill_level = {poor, average, good}.
#limb = {arm, leg}.

%%--------
%% Fluents
%%--------

#inertial_fluent = on(#thing(X), #obj_w_zloc(Y)):X!=Y +
		   z_loc(#obj_w_zloc, #vertsz) + 
		   location(#obj_w_zloc, #area) + 
		   in_hand(#agent, #object).

#defined_fluent = in_range(#obj_w_zloc, #obj_w_zloc, #vertsz) + 
		  can_support(#obj_w_zloc(X), #thing(Y)):X!=Y.

#fluent = #inertial_fluent + #defined_fluent.


%%-----------
%% Predicates
%%-----------

predicates

holds(#fluent, #step).
%occurs(#action, #step).

height(#obj_w_zloc, #vertsz).
has_weight(#thing, #weight).
has_surf(#obj_w_zloc, #bool).
material(#obj_w_zloc, #substance).

joint_mobility(#agent, #limb, #skill_level).
limb_strength(#agent, #limb, #skill_level).

has_exit(#area, #exit). 

% planning: not in the original AL description.
success().
goal(#step). 
something_happened(#step).

%%-----------------------------------------------------------
%%                         Rules
%%-----------------------------------------------------------

rules

%%---------------------
%% II State Constraints
%% --------------------

% 1. 
-holds(on(O, S), I) :- holds(on(O2, S), I), O!=O2, #object(S).

% 2. 
holds(z_loc(O, Z+H), I) :- holds(on(O, S), I), 
			   holds(z_loc(S, Z), I), 
			   height(O, H).

% 3.
-holds(on(O, S), I) :- holds(on(O, S2), I), 
		       #thing(O), 
		       S!=S2.
 
% 4.
-height(O, H2) :- height(O, H), H!=H2.

% 5. CWA for locations
-holds(location(O, L), I) :- holds(location(O, L2), I), L!=L2.

% 6. things can't be on things in other locations
-holds(on(X,Y),I) :- holds(location(X, L), I), holds(location(Y, L2), I), L!=L2.

% 7. things can't be in hands of agents in other locations
-holds(in_hand(X,Y),I) :- holds(location(X, L), I), holds(location(Y, L2), I), L!=L2.

% 8. things on things can't be in hands
-holds(in_hand(A, X),I) :- holds(on(X, Y), I).

				   
% Support Rules:
% 1.
holds(can_support(S, O), I) :- has_weight(O, light),
                               material(S, glass), has_surf(S, true).
                               
% 2. 
holds(can_support(S, O), I) :- not has_weight(O, heavy), 
                               material(S, plastic), has_surf(S, true).

% 3. 
holds(can_support(S, O), I) :- not has_weight(O, heavy),
                               material(S, paper), has_surf(S, true).

% 4. 
holds(can_support(S, O), I) :- material(S, wood), has_surf(S, true).

% 5.				  
-holds(can_support(S, O), I) :- holds(on(S, S2), I), 
                                not holds(can_support(S2, O), I).

% 6. impossible to be on something that doesn't have a surface
-holds(on(X, Y),I) :- has_surf(Y, false). 
-holds(can_support(Y, X),I) :- has_surf(Y, false). 
%-holds(can_support(X, Y),I) :- not has_surf(Y, true). 
-holds(on(X,Y),I) :- not holds(can_support(Y,X),I). 

% 7. 
-holds(z_loc(X, Z),I) :- holds(z_loc(X, Z2), I), Z!=Z2.

% 8. 
-holds(in_hand(A, O), I) :- holds(in_hand(A, O2), I), O!=O2.

% 9. Can't have more than two objects made out of glass or paper or card:
%:- material(A,paper), material(B,paper), A!=B.
%:- material(A,glass), material(B,glass), A!=B. 
%:- material(A,plastic), material(B,plastic), material(C, plastic), A!=B, B!=C, C!=A. 

% 10. Objects made out of paper or card can't be heavy
:- has_weight(O,heavy), material(O,paper). 
:- has_weight(O,heavy), material(O,plastic).

% 11. Generate a minimal number of objects in the same room as the agent so as to prevent running dead-end simulations
%:- holds(location(robot, Ar1),0), -holds(location(Ob1,Ar1),0), -holds(location(Ob2,Ar1),0), 
%                                  -holds(location(Ob3,Ar1),0), 
%                                  Ob1!=Ob2, Ob2!=Ob3, Ob1!=Ob3.
                       

%%---------------------------------------------------------
%%                   Inertia Axiom + CWA
%%---------------------------------------------------------

% CWA for predicates
%-height(O, H) :- height(O, H2), H!=H2.
%-has_weight(A, W) :- has_weight(A, W2), W!=W2.  
%-has_surf(A, B) :- has_surf(A, C), C!=B.
%-material(A, B) :- material(A, C), C!=B.

% CWA for Defined fluents
-holds(F,I) :- not holds(F,I), #defined_fluent(F).

%%---------------
%% I Generation Rules
%%---------------


1{holds(on(X, floor), 0); holds(on(X,box3),0); holds(on(X,box4),0)}1 :- #thing(X), X=chair.  
1{holds(on(X, floor), 0); holds(on(X,box2),0); holds(on(X,box3),0)}1 :- #thing(X), X=box1.  
1{holds(on(X, floor), 0); holds(on(X,box3),0)}1 :- #thing(X), X=box2.  
1{holds(on(X, floor), 0); holds(on(X,box2),0); holds(on(X,box3),0)}1 :- #thing(X), X=robot.  

% If it exists, it must have a location
%1{holds(location(X, Ar), I); holds(location(X, Ar2)}1 :- #thing(X), #area(Ar), #area(Ar2), Ar!=Ar2.
1{holds(location(cup, room), I); holds(location(cup, corridor),I)}1.
1{holds(location(box5, room), I); holds(location(box5, corridor),I)}1.

1{holds(on(X, floor_cor), 0); holds(on(X,floor),0)}1 :- #thing(X), X=box5.  

% if it exists, it must have height. The range is different for agents, objects and static objects:
% Object height is between 1-4
% Door height is 1-3
%1{height(X,1); height(X,2); height(X,3); height(X,4)}1 :- #object(X), X!=cup.
%1{height(X,1); height(X,2); height(X,3); height(X,4)}1 :- #object(X), X!=cup.
1{height(X,2); height(X,3)}1 :- #exit(X), X=door.
%1{height(X,1); height(X,2); height(X,3); height(X,4)}1 :- exit(X), X=window.
1{height(X,2); height(X,3)}1 :- #object(X), X=box5.
1{height(X,1); height(X,2)}1 :- #object(X), X=box3.
%1{height(X,2); height(X,3)}1 :- #exit(X).
 
%% VARIABLE PARAMETERS
% Objects are made of a particular substance
%1{material(X, paper); material(X, plastic); material(X, wood); material(X, glass)}1 :- #object(X).
1{material(X, paper); material(X, plastic); material(X, glass)}1 :- #object(X), X=box1.
1{material(X, paper); material(X, plastic); material(X, glass)}1 :- #object(X), X=cup.
1{material(X, wood); material(X, plastic)}1 :- #object(X), X=box2.
1{material(X, plastic); material(X, wood)}1 :- #object(X), X=chair.

% Things have weight
%1{has_weight(X, light); has_weight(X, medium); has_weight(X,heavy)}1 :- #thing(X).
%1{has_weight(X, W)}1 :- #thing(X), #weight(W).
1{has_weight(X, medium); has_weight(X,heavy)}1 :- #thing(X), X=chair.
1{has_weight(X, medium); has_weight(X,heavy)}1 :- #thing(X), X=robot.
1{has_weight(X, medium); has_weight(X,heavy)}1 :- #thing(X), X=box2.

% Agents have a strength level
%1{has_power(A, weak); has_power(A,strong)}1 :- #agent(A).

holds(on(X, floor_cor), 0) :- holds(location(X, corridor),0), #thing(X), X=cup.
1{holds(on(X,box5),0); holds(on(X,box1),0)}1 :- holds(location(X, room),0), #thing(X), X=cup. 


%%------------------
%% Initial Condition
%%------------------

%% CONSTANT CONDITIONS:
%holds(on(robot, floor),0).
%holds(location(robot, room),0).
has_exit(room, door).
has_exit(corridor, door).

has_surf(box1, true).
has_surf(box2, true).
has_surf(box3, true).
has_surf(box4, true).
has_surf(box5, true).
has_surf(floor, true).
has_surf(cup, false).
has_surf(chair, true).
has_surf(door, false).
has_surf(robot,false).

material(floor, wood).
material(box4, wood).
material(box3, wood).
material(box5, wood).

holds(z_loc(floor,0),0).
holds(z_loc(door,6),0).

holds(on(box3, floor), 0).
holds(on(box4, floor), 0).
holds(on(box5, floor), 0).

holds(location(robot, room),0).
holds(location(box1, room),0).
holds(location(box2, room),0).
holds(location(box3, room),0).
holds(location(box4, room),0).
holds(location(chair, room),0).

height(floor, 0).
height(cup, 1).
height(chair,1).
%height(door, 3).
height(box1, 1). 
height(box2, 1). 
height(box4, 3).
height(robot, 2).

holds(location(floor_cor,corridor),0).
holds(location(floor,room),0).
material(floor_cor,wood).
has_surf(floor_cor, true).
height(floor_cor,0).
holds(z_loc(floor_cor,0),0).

joint_mobility(robot, leg, good).
limb_strength(robot, leg, good).
joint_mobility(robot, arm, good).
limb_strength(robot, arm, good).

has_weight(box1, light).
has_weight(box3, medium).
has_weight(box4, medium).
has_weight(box5, medium).
has_weight(cup, light).


%%

%% VARIABLE CONDITIONS
%material(box1, paper).
%material(box2, wood).
%material(box3, wood).
%material(box4, wood).
%material(box5,cardboard).

%has_weight(box1, light).
%has_weight(box2, medium).
%has_weight(box3, medium).
%has_weight(box4, heavy).
%has_weight(robot, medium). 






display

has_exit.
material.
has_weight.
height.
limb_strength.
has_surf.
joint_mobility.
holds.
%


