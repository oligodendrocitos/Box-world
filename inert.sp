#const n=1.

%%%%%%%%%%%%%
%%% SORTS %%%
%%%%%%%%%%%%%

sorts

%% Things
#box = {box1, box2, box3, box4}.
#robot = {bot}.
#static_obj = {floor}. 
#thing = #box + #robot. 
#object = #box.
#surf = #box + #static_obj.
%% Things that have a 3d location:. 
#obj_w_zloc = #thing + #static_obj.

%% Properties
#vertsz = 0..6. % units of length for Z for height and z location

%% Time and affordance indices
#step = 0..n.
#id = 10..20.
#bool = {true, false}.

%%%%%%%%%%%%%%%
%%% fluents %%%
%%%%%%%%%%%%%%%

#inertial_fluent = on(#thing(X), #surf(Y)):X!=Y + z_loc(#obj_w_zloc(X), #vertsz).

#def_fluent = in_range(#obj_w_zloc, #robot).

%#def_fluent = in_range(#obj_w_zloc, #robot) + z_loc(#obj_w_zloc(X), #vertsz).

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
holds(on(R,S),T+1) :- occurs(go_to(R,S),T).

% move_to (X, Y), causes on(X, Y)
holds(on(O,S),T+1):- occurs(move_to(R,O,S),T).

                    

%%%%%%%%%%%%%%%%%%%
% State Constraints

% two things can't be at the same location, unless it's the floor
-holds(on(O,S),T) :- holds(on(O2,S),T),
                     #box(S),
                     O!=O2.

% ON defines 3dlocation
holds(z_loc(O,L+H),T) :- holds(on(O,S),T),
                         height(O,H),
                         holds(z_loc(S,L),T).


% z_loc defines whether in range
holds(in_range(O,R),T) :- holds(z_loc(O,LO),T),
                          holds(z_loc(R,LR),T),
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

% can't move objects out of reach
-occurs(move_to(R,O,S),T) :- not holds(in_range(O,R),T).

%-occurs(pick_up(R,O),T) :- not holds(z_loc(R,L1),T),
%                           not holds(z_loc(O,L2),T),
%                           height(R,H),
%                           L2<=L1.


% don't go to the same place you already are
-occurs(move_to(R,O,S),I) :- holds(on(O,S),I).
-occurs(go_to(R,S),I) :- holds(on(R,S),I).

% move not possible if something is on the object
-occurs(move_to(R,O,S),I) :- holds(on(O2, O), I).

% move/go_to not possible if something is on the box
-occurs(go_to(R,O),I) :- holds(on(O2, O), I),
                         #box(O).

% move to possible if destination is within reach of arms/bot
%-occurs(move_to(R,O,S),T) :- holds(z_loc(S,L1),T),
%                             holds(z_loc(R,L2),T),
%                             height(R,H),
%                             L1<(L2-H).

% move to possible if destination is within reach of arms/bot
%-occurs(move_to(R,O,S),T) :- holds(z_loc(S,L1),T),
%                             holds(z_loc(R,L2),T),
%                             height(R,H),
%                             L1>L2.
					   
%%%%%%%%%%%%%%%%					   
% Inertia Axiom: 

holds(F, I+1) :- #fluent(F),
		holds(F, I),
		not -holds(F, I+1).

-holds(F, I2) :- #fluent(F),
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



%%%%%%%%%%%%%%
%%% GROUND %%%
%%%%%%%%%%%%%%

height(bot, 3).
height(floor, 0).
height(box1, 1). 
height(box2, 1). 
height(box3, 1).

holds(z_loc(floor,0),0).
% hanging object
holds(z_loc(box4,5),0).

holds(on(box1,box3),0). holds(on(box2,floor),0). holds(on(box3,floor),0).
holds(on(bot, floor),0).

%goal(I) :- holds(in_hand(bananas,bot), I). 
goal(I) :- holds(z_loc(box2,3), I). 


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
display
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
occurs.
goal.
holds.
-holds.
height.

 
 
 
 
 
 
