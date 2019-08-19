%% --------------------------------------------
%% BW domain
%% Translation from Action Language Description
%% of the domain layout including some of the 
%% available object & agent properties, actions, 
%% a simple planning module, affordance relations
%% and their corresponding executability conditions. 
%% Most affordance relations defined here can be
%% rewritten; they act as simple executability conditions. 
%% These are a rudiment of the previous version of this 
%% program.
%% --------------------------------------------

#const n=3.

sorts

#area = {room, corridor}.
#exit = {door}.

#box = {box1, box2, box3, box4, box5}.
#other = {apple}.
#agent = {robot}.  %, human}.
#fixed_element = {floor, door}.
#object = #box + #other.
#thing = #object + #agent.

#obj_w_zloc = #thing + #fixed_element.
#surf = #box+{floor}.

#vertsz = 0..15.
#step = 0..n.
#id = 10..30.


#substance = {paper, cardboard, wood, bio}.
#power = {weak, strong}.
#weight = {light, medium, heavy}.

%%--------
%% Fluents
%%--------

#inertial_fluent = on(#thing(X), #surf(Y)):X!=Y +
		   z_loc(#obj_w_zloc, #vertsz) + 
		   location(#thing, #area) + 
		   in_hand(#agent, #object).

#defined_fluent = in_range(#obj_w_zloc, #obj_w_zloc, #vertsz) + 
		  can_support(#surf, #thing).

#fluent = #inertial_fluent + #defined_fluent.

%%--------
%% Actions 
%%--------

#action = go_to(#agent, #surf) +
          move_to(#agent, #object(X), #surf(Y)):X!=Y +
          go_through(#agent, #exit, #area) +
          pick_up(#agent, #object). 
          
          
%%-----------
%% Predicates
%%-----------

predicates

holds(#fluent, #step).
occurs(#action, #step).

height(#obj_w_zloc, #vertsz).
has_power(#agent, #power).
has_weight(#thing, #weight).
material(#object, #substance).

has_exit(#area, #exit). 

% affordance predicates
affordance_permits(#action, #step, #id).
affordance_forbids(#action, #step, #id).



% planning: not in the original AL description.
success().
goal(#step). 
something_happened(#step).


%%-----------------------------------------------------------
%%                         Rules
%%-----------------------------------------------------------

rules

%%---------------
%% I Causal Laws
%%---------------

% 1.
holds(on(A, S), I+1) :- occurs(go_to(A, S), I).

% 2. 
holds(on(O, S), I+1) :- occurs(move_to(A, O, S), I).

% 3. 
-holds(in_hand(A, O), I+1) :- occurs(move_to(A, O, S), I).

% 4. 
holds(z_loc(A, Z+H), I+1) :- occurs(go_to(A, S), I),
			     height(A, H), 
			     holds(z_loc(S, Z), I). 

% 5. 
holds(location(A, L), I+1) :- occurs(go_through(A, D, L), I).

% 6. 
holds(z_loc(O, Z+H), I+1) :- occurs(move_to(A, O, S), I),  
			     holds(z_loc(S, Z), I), 
			     height(O, H).

% 7.
holds(in_hand(A, O), I+1) :- occurs(pick_up(A, O), I).

% 8.
-holds(on(O, S), I+1) :- occurs(pick_up(A, O), I),
			 holds(on(O, S), I).

% 9. 
-holds(z_loc(O, Z), I+1) :- occurs(pick_up(A, O), I), 
			    holds(z_loc(O, Z), I).

% 10.
-holds(on(A, S), I+1) :- occurs(go_to(A, S2), I),
			 holds(on(A, S), I). 

% 11.
-holds(z_loc(A, Z), I+1) :- occurs(go_to(A, S), I), 
			    holds(z_loc(A, Z), I).



%%---------------------
%% II State Constraints
%% --------------------

% 1. 
-holds(on(O, S), I) :- holds(on(O2, S), I), O!=O2, #box(S).

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

% 5.
-holds(location(O, L), I) :- holds(location(O, L2), I), L!=L2.

% 6.
holds(in_range(Ob1, Ob2, X), I) :- holds(z_loc(Ob1, Z1), I), 
				   holds(z_loc(Ob2, Z2), I),
				   height(Ob1, H1),
				   height(Ob2, H2),
				   Z1 - H1 > Z2 - H2, 
				   X = (Z1 - H1) - (Z2 - H2).
				   
% 7.
holds(can_support(S, O), I) :- has_weight(O, light),
                               material(S, bio).
                               
 
% 8. 
holds(can_support(S, O), I) :- not has_weight(O, heavy), 
                               material(S, cardboard).

% 9. 
holds(can_support(S, O), I) :- not has_weight(O, heavy),
                               material(S, paper).

% 10. 
holds(can_support(S, O), I) :- material(S, wood).

% 11.				  
-holds(can_support(S, O), I) :- holds(on(S, S2), I), 
                                not holds(can_support(S2, O), I).


%% ----------------------------
%% III Executability Conditions
%%-----------------------------

% 1.
-occurs(pick_up(A, O), I) :- holds(in_hand(A, O2), I).

% 2.
-occurs(move_to(A, O, S), I) :- not holds(in_hand(A, O), I).

% 3.
-occurs(go_to(A, S), I) :- holds(on(A, S), I).

% 4.
-occurs(pick_up(A, O), I) :- holds(on(O2, O), I).

% 5.
-occurs(go_to(A, S), I) :- holds(on(O, S), I), #box(S). 

% 6.
-occurs(move_to(A, O, S), I) :- holds(on(O2, S), I), #box(S).

% 7.
-occurs(go_through(A, D, Loc2), I) :- not holds(location(A, Loc1), I),
				      not has_exit(Loc1, D),
				      not has_exit(Loc2, D).

% 8.
-occurs(go_to(A, S), I) :- holds(in_hand(A2, S), I).

% 9. 
-occurs(go_to(A, S), I) :- holds(z_loc(S, Z), I), 
                           holds(z_loc(A, Z2), I),
                           height(A, H),
                           Z2 - H = BASE, 
                           Z < BASE - 1.

% 10. 
-occurs(go_to(A, S), I) :- holds(z_loc(S, Z), I), 
                           holds(z_loc(A, Z2), I), 
                           height(A, H), 
                           Z2 - H = BASE, 
                           Z > BASE + 1. 
                           
%% ------------------------------
%% Exec. conditions + affordances
%% ------------------------------                   

% 1. 
-occurs(A, I) :- affordance_forbids(A, I, ID).

% 2.
-occurs(pick_up(A, O), I) :- not affordance_permits(pick_up(R, O), I, 17).

% 3. 
-occurs(go_through(A, D, R), I) :- not affordance_permits(go_through(A, D, R), 26).

% 4.
-occurs(pick_up(A, O), I) :- has_weight(O, medium), 
                             not affordance_permits(pick_up(A, O), I, 10).

% 5.
-occurs(pick_up(A, O), I) :- has_weight(O, heavy), 
                             not affordance_permits(pick_up(R, O), 10).
                             

%%---------------------------------------------------------
%%                   Inertia Axiom + CWA
%%---------------------------------------------------------


% Inertial fluents
holds(F, I+1) :- #inertial_fluent(F),
		holds(F, I),
		not -holds(F, I+1).

-holds(F, I+1) :- #inertial_fluent(F),
		 -holds(F, I),
		 not holds(F, I+1). 


% CWA for Defined fluents
-holds(F,I) :- not holds(F,I), #defined_fluent(F).


% CWA for actions
-occurs(A, I) :- not occurs(A, I).


%%---------------------------------------------------------
%%                         Planning
%%---------------------------------------------------------


success :- goal(I),
           I <= n. 
:- not success.

% an action must occur at each step
occurs(A,I) | -occurs(A,I) :- not goal(I).

% do not allow concurrent actions
:- occurs(A1, I),
   occurs(A2, I),
   A1!=A2.

% forbid agents from procrastinating
something_happened(I) :- occurs(A,I).

:- not something_happened(I),
   something_happened(I+1).

:- goal(I), goal(I-1),
   J < I,
   not something_happened(J).
   
   
%% ------------------------------------------------------------
%%                   Affordance Relations
%% ------------------------------------------------------------

% 1. 
% ID #10 
affordance_permits(pick_up(A, O), I, 10) :- has_power(A, strong).


% 2.
% ID #17
affordance_permits(pick_up(A, O), I, 17) :- height(A, H), height(O, HO), 
                                            holds(in_range(O, R, X), I),
                                            X < H,
                                            X >=0.

% 3. 
% ID #25
affordance_permits(go_through(A, D, L), I, 25) :- affordance_permits(go_to(A, S), ID),
                                                  height(A, HA),
                                                  height(D, HD), 
                                                  height(S, HS),
                                                  holds(in_range(D, S, X), I),
                                                  HS + HA > X,
                                                  HS < X + HD.

% 4.
% ID #26
affordance_permits(go_through(A, D, L), I, 26) :- holds(on(A, S), I),
                                                  height(A, HA),
                                                  height(D, HD),
                                                  height(s, HS),
                                                  holds(in_range(D, S, X), I), 
                                                  HS + HR > X,
                                                  HS < X + HD.

%%------------------
%% Initial Condition
%%------------------

has_exit(room, door).
has_exit(corridor, door).


height(robot, 2).
height(floor, 0).

height(box1, 1). 
height(box2, 1). 
height(box3, 1).
height(box4, 3).

height(door, 3).
height(apple, 1).


holds(z_loc(floor,0),0).
holds(z_loc(door,7),0).


holds(on(box1,box3),0). 
holds(on(box2,floor),0). 
holds(on(box3,floor),0).
holds(on(box4, floor),0). 
%holds(on(apple, box4),0).
holds(on(robot, floor),0).

holds(location(robot, room),0).


% Queries:


% Goals:
%goal(I) :- holds(z_loc(robot, 6), I).
%goal(I) :- holds(z_loc(box2, 3), I).
goal(I) :- holds(location(robot, corridor), I).
%goal(I) :- holds(on(box3, box1), I).


display

goal.
occurs.
%holds.


