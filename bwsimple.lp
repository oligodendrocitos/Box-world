%%-----
% Sorts
%%-----

% time indices
#const n = 10.
step(0..n).


% units of length/distance
vertsz(0..15).

% 1. enclosed spaces
area(room). area(corridor).
% 2. openings
exit(door).
%% 3. boxes
box(box1). box(box2). box(box3). box(box4). box(box5).
%% 4. other objects in the domain
other(apple).
%% 5. entities that perceive and act
%% Human to be removed (each agent has its own program)
agent(robot). agent(human). 
%% 6. things that don't change their location
fixed_element(floor).
fixed_element(door).
%% 7. things that can be acted upon
object(X) :- box(X). 
object(X) :- other(X).
%% 8. things that are mobile
thing(X) :- object(X).
thing(X) :- agent(X).
%% 9. things that have a 3D location
obj_w_zloc(X) :- thing(X).
obj_w_zloc(X) :- fixed_element(X).
%% 10. things that have a surface
surf(X) :- box(X).
surf(X) :- fixed_element(X), X=floor.

%%-------
%% fluents
%%-------

%% or should all these be of the form:
fluent(inertial, on(X, Y)) :- thing(X), surf(Y), X!=Y.
fluent(inertial, z_loc(X, Y)) :- obj_w_zloc(X), vertsz(Y).
fluent(inertial, location(X, Y)) :- thing(X), area(Y).
fluent(inertial, in_hand(X, Y)) :- agent(X), object(Y).

% fluent(defined, in_range(obj_w_zloc, obj_w_zloc, vertsz)).
fluent(defined, in_range(OB1, OB2, X)) :- obj_w_zloc(OB1), obj_w_zloc(OB2), vertsz(X).
fluent(defined, can_support(S, T)) :- surf(S), thing(T).

%%-------
% Actions
%%-------

action(go_to(A, S)) :- agent(A), surf(S). 
action(move_to(A, O, S)) :- agent(A), surf(S), object(O), S!=O.
action(go_through(A, D, L)) :- agent(A), exit(D), area(L).
action(pick_up(A, O)) :- agent(A), object(O). 

%%----------
% Predicates
%%----------

height(O, H) :- obj_w_zloc(O), vertsz(H).
has_exit(A, D) :- area(A), exit(D).
%%occurs(A, I) :- action(A), step(I).
%%holds(F, I) :- fluent(ID, F), step(I).
%%goal(I) :- step(I).
success().
%%something_happened(I) :- step(I).

%%------------
%% Causal Laws
%%------------

%% 1. go_to causes an agent to be on the surface it went to:
holds(on(A,S), I+1) :- occurs(go_to(A, S), I), I<n.

%% 2. move_to(A,O,S) causes on(O, S).
holds(on(O,S), I+1) :- occurs(move_to(A,O,S), I), I<n.

%% 3. move_to(A, O, S) causes ¬in_hand(A,O).
-holds(in_hand(A,O), I+1) :- occurs(move_to(A,O,S), I), I<n.

%% 4. go_to(A,S), causes zloc(A, Z+H) if height(A,H), z_loc(S,Z).
holds(z_loc(A, Z+H), I+1) :- occurs(go_to(A,S),I),
			     height(A,H),
			     holds(z_loc(S,Z),I), I<n.

%% 5. go_through(A,D,L) causes location(A,L).
holds(location(A,L),I+1) :- occurs(go_through(A,D,L), I), I<n.

%% 6. move_to(A,O,S) causes zloc(O, Z+H) if zloc(O,Z).
holds(z_loc(O, Z+H), I+1) :- occurs(move_to(A, O, S), I), 
				 holds(z_loc(O, Z), I), 
				 height(O, H), I<n.

% 7. pick up(A; O) causes in hand(A; O)
holds(in_hand(A, O), I+1) :- occurs(pick_up(A, O), I), I<n.

% 8. pick up(A; O) causes ¬on(O; S) if on(O; S)
-holds(on(O, S), I+1) :- occurs(pick_up(A, O), I),
			 holds(on(O,S), I), I<n.

% 9. pick up(A; O) causes ¬z loc(O; Z) if z loc(O; Z)
-holds(z_loc(O,Z), I+1)  :-  holds(z_loc(O, Z), I),
			     occurs(pick_up(A, O), I), I<n.

%% 10. go to( A; S2) causes ¬on( A; S)if on( A; S)
-holds(on(A, S1), I+1) :- surf(S2), surf(S1), occurs(go_to(A, S2), I), S1!=S2, I<n.

%% 11. go to( A; S) causes ¬z loc( A; Z) if z loc( A; Z)
-holds(z_loc(A, Z), I+1) :- agent(A), vertsz(Z),
	      		   holds(z_loc(A, Z), I),
			   occurs(go_to(A, S), I),
			   not holds(in_range(A, S, 0), I), I<n.

%%-----------------
%% State Constraints
%%-----------------

%%1. ¬on(O; S) if on(O2; S); O=/=O2, box(S)
-holds(on(O, S), I) :- box(S),
                       thing(O),
		       holds(on(O2, S), I), 
		       O != O2.

-holds(on(O,S),T) :- box(S),
                     thing(O), thing(O2),
                     holds(on(O2,S),T),
                     O!=O2.

%%2. z loc(O; Z + H) if on(O; S); height(O; H); z loc(S; Z)
holds(z_loc(O, Z+H), I) :- holds(on(O, S), I),
			   holds(z_loc(S, Z), I), 
			   height(O, H).

%%3. ¬on(O; S) if on(O; S2); thing(O); S 6= S2
-holds(on(O, S), I) :- thing(O), 
                       surf(S), surf(S2),
                       holds(on(O, S2), I), 
			   S != S2.

%%4. ¬height(O; H2) if height(O; H1); H 6= H2
-height(X, H2) :- vertsz(H2), vertsz(H),
				  height(X, H), 
				  H != H2.


%%5. :location(O; L) if location(O; L2); L 6= L2
-holds(location(O, L), I) :- area(L), area(L2), 
                             holds(location(O, L2),I),
			     L != L2.


%% 6. . in range(O1; O2; X) if z loc(O1; Z1); z loc(O2; Z2);
%% Height(O1; H1); height(O2; H2);
%% (Z1 − H1) ≥ (Z2 − H2);
%% X = (Z1 − H1) − (Z2 − H2)
%% -(X,Y,Z), or alternatively: Z=X-Y is true, iff Z=X-Y holds.
%% What determines the correct sequence of literals in the body?

holds(in_range(O1, O2, X), I) :- vertsz(H1), vertsz(H2), 
				 obj_w_zloc(O1), obj_w_zloc(O2), vertsz(Z2),
				 DIFF1 = Z1-H1, DIFF2 = Z2-H2,
				 vertsz(DIFF1), vertsz(DIFF2),
				 DIFF1 >= DIFF2,
				 X = DIFF1 - DIFF2,
				 holds(z_loc(O1, Z1),I),
				 holds(z_loc(O2, Z2),I), 
				 height(O1, H1), height(O2, H2).



%%------------------------
%% Executability Conditions
%%------------------------

%% 1. Impossible pick_up(A, O) if in_hand(A, O2)
-occurs(pick_up(A, O), I) :- agent(A), object(O),				 	 				holds(in_hand(A, O2), I).

%% 2. impossible move_to(A, O, S) if not in_hand(A, O)
-occurs(move_to(A, O, S), I) :- agent(A), object(O), surf(S), step(I),
				not holds(in_hand(A, O), I).

%% 3. impossible go_to(A, S) if on(A, S)
-occurs(go_to(A,S), I) :- holds(on(A, S), I).


%% 4. impossible pick_up(A, O), if on(O2, O)
-occurs(pick_up(A, O), I) :- holds(on(O2, O), I), agent(A).

%% 5. impossible go_to(A, S) if on(O2, S), box(O)
-occurs(go_to(A, S), I) :- holds(on(O2, S), I), box(O), agent(A).

%% 6. impossible move_to(A, O, S) if on(O2, O), box(O)
-occurs(move_to(A, O, S), I) :- box(O), agent(A), surf(S),
								holds(on(O2, O), I).

%% 7. impossible go_through(A, E, L1) if not location(A, L0)
%%   not has_exit(L0, E)
%%   not has_exit(L1, E)
-occurs(go_through(A, E, L1), I) :- step(I), agent(A), exit(E), area(L1), area(L0),
				not holds(location(A, L0), I),
				not has_exit(L0, E),
				not has_exit(L1, E).

%% 8. impossible go_to(A, S) if in_hand(A2, S)
-occurs(go_to(A, S), I) :- holds(in_hand(A2, S), I), surf(S), agent(A).


%%-------------
%% Inertia Axiom
%%-------------

holds(F, I+1) :- fluent(inertial, F),
				 holds(F, I), 
				 not -holds(F, I+1), 
                 			I < n.

-holds(F, I+1) :- fluent(inertial, F),
				  -holds(F, I), 
				  not holds(F, I+1), 
                  			I < n.


%%----
%% CWA
%%----

-occurs(A, I) :- action(A), step(I),
				 not occurs(A, I).

-holds(F,I) :- not holds(F,I),
			   fluent(defined, F),
			   step(I).


%%---------------
%% Planning module
%%---------------

success :- goal(I),
		   I <= n.

:- not success.

occurs(A,I) | -occurs(A, I) :- step(I), action(A),
				   not goal(I),
				   I < n. 

%% do not allow concurrent actions
:- action(A1), action(A2),
   occurs(A1, I),
   occurs(A2, I),
   A1!=A2.

%% forbid agents from procrastinating
something_happened(I) :- occurs(A,I).

:- step(I),
   not something_happened(I),
   something_happened(I+1).

:- step(I), step(J), goal(I), goal(I-1),
   J < I,
   not something_happened(J).

%%-----------------
%% Initial Situation
%%-----------------

has_exit(room, door).
has_exit(corridor, door).

height(robot, 2).
height(human, 1).
height(floor, 0).
height(box1, 1). 
height(box2, 1). 
height(box3, 1).
height(box4, 3).
height(box5, 1).
height(door, 3).
height(apple, 1).


%% as floor is an independent object, just add this to make sure it's not causing trouble
holds(z_loc(floor,0),0).
holds(z_loc(floor,0),1).
holds(z_loc(floor,0),2).
holds(z_loc(floor,0),3).
holds(z_loc(door,7),0).

holds(on(box1,box3),0). holds(on(box2,floor),0). holds(on(box3,floor),0).
holds(on(box5, floor),0).
holds(on(box4, floor),0). 
holds(on(apple, box4),0).
holds(on(robot, floor),0).
holds(location(robot, room),0).
holds(location(human, room),0).

%%----
%% Goal
%%----

%% goal(I) :- holds(z_loc(robot,5), I). % this should be impossible with two wooden and one paper box if robot height is 2

%% goal(I) :- holds(location(robot,corridor), I), holds(location(human, corridor),I). 
%% goal(I) :- holds(location(human, corridor),I). 
goal(I) :- holds(location(robot,corridor), I). % N.B. if apple is on box4, this needs >6 iterations
%% goal(I) :- holds(on(robot,box4), I).  
%% goal(I) :- holds(in_hand(robot,box1), I). 
%% goal(I) :- holds(on(box1, box2), I). 
%% goal(I) :- holds(in_hand(robot, apple),I).

%%
%% output
%%

#show occurs/2.
