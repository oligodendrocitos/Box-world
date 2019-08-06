%% --------------------------------------------
%% BW domain
%% This is a script for simulating the agents'
%% actions in the 'real world' - the program 
%% contains complete domain knowledge and thus
%% generates realistic feedback about the successful
%% actions and their consequences. 
%% occurs: actions proposed by the planner
%% hpd: actions that actually happen
%% possible: actions that are possible (ground truth).
%% 
%% Init. conditions added from the complete
%% knowledge domain. 
%% --------------------------------------------

#const n=9.

sorts

#area = {room, corridor}.
#exit = {door}.

#agent = {robot}.  %, human}.
#fixed_element = {floor, door}.
#object = {box1, box2, box3, box4, box5, cup}.
#thing = #object + #agent.

#obj_w_zloc = #thing + #fixed_element.

#vertsz = 0..15.
#step = 0..n.
#id = 10..30.
#bool = {true, false}.

%% VARIABLE PARAMETERS
#substance = {paper, cardboard, wood, glass}.
#power = {weak, strong}.
#weight = {light, medium, heavy}.

%%--------
%% Fluents
%%--------

#inertial_fluent = on(#thing(X), #obj_w_zloc(Y)):X!=Y +
		   z_loc(#obj_w_zloc, #vertsz) + 
		   location(#thing, #area) + 
		   in_hand(#agent, #object).

#defined_fluent = in_range(#obj_w_zloc, #obj_w_zloc, #vertsz) + 
		  can_support(#obj_w_zloc(X), #thing(Y)):X!=Y.

#fluent = #inertial_fluent + #defined_fluent.

%%--------
%% Actions 
%%--------

#hypothetical_action = {fails}.

#action = go_to(#agent, #obj_w_zloc) +
          put_down(#agent, #object(X), #obj_w_zloc(Y)):X!=Y +
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
has_surf(#obj_w_zloc, #bool).
material(#obj_w_zloc, #substance).

has_exit(#area, #exit). 

% affordance predicates
affordance_permits(#action, #step, #id).
affordance_forbids(#action, #step, #id).

% planning: not in the original AL description.
success().
goal(#step). 
something_happened(#step).
plan_length(#step).

% History and initial state predicates
obs(#fluent, #bool, #step).
hpd(#action, #step).
is_defined(#fluent).
expl(#action, #step).
possible(#action, #step). 
fails(#action, #step). 

%%-----------------------------------------------------------
%%                         Rules
%%-----------------------------------------------------------

rules

%%---------------
%% I Causal Laws
%%---------------

%% In this section, occurs is replaced by hpd
%% to  

% 1.
holds(on(A, S), I+1) :- hpd(go_to(A, S), I).

% 2. 
holds(on(O, S), I+1) :- hpd(put_down(A, O, S), I), holds(in_hand(A,O),I), #object(O).

% 3. 
-holds(in_hand(A, O), I+1) :- hpd(put_down(A, O, S), I).

% 4. 
holds(z_loc(A, Z+H), I+1) :- hpd(go_to(A, S), I),
			     height(A, H), 
			     holds(z_loc(S, Z), I). 

% 5. 
holds(location(A, L), I+1) :- hpd(go_through(A, D, L), I).

% 6. 
% Assume agent ends up on the floor if location is changed
holds(on(A, floor), I+1) :- hpd(go_through(A, D, L), I).

% 7. 
holds(z_loc(O, Z+H), I+1) :- hpd(put_down(A, O, S), I),  
			     holds(z_loc(S, Z), I), 
			     height(O, H).

% 8.
holds(in_hand(A, O), I+1) :- hpd(pick_up(A, O), I).

% 9.
-holds(on(O, S), I+1) :- hpd(pick_up(A, O), I),
			 holds(on(O, S), I).

% 10. 
-holds(z_loc(O, Z), I+1) :- hpd(pick_up(A, O), I), 
			    holds(z_loc(O, Z), I).

% 11.
-holds(on(A, S), I+1) :- hpd(go_to(A, S2), I),
			 holds(on(A, S), I). 

% 12.
-holds(z_loc(A, Z), I+1) :- hpd(go_to(A, S), I), 
			    holds(z_loc(A, Z), I).

% 13. 
% 5. 
-holds(location(A, L), I+1) :- hpd(go_through(A, D, L2), I), holds(location(A,L),I), L2!=L.

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

% 5.
-holds(location(O, L), I) :- holds(location(O, L2), I), L!=L2.

% 6.
holds(in_range(Ob1, Ob2, X), I) :- holds(z_loc(Ob1, Z1), I), 
				   holds(z_loc(Ob2, Z2), I),
				   height(Ob1, H1),
				   height(Ob2, H2),
				   Z1 - H1 >= Z2 - H2, 
				   X = (Z1 - H1) - (Z2 - H2).
				   
% 7.
holds(can_support(S, O), I) :- has_weight(O, light),
                               material(S, glass).
                               
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

% 12. impossible to be on something that doesn't have a surface
-holds(on(X, Y),I) :- not has_surf(Y, true). 


%% ----------------------------
%% III Executability Conditions
%%-----------------------------

% 1.
-possible(pick_up(A, O), I) :- holds(in_hand(A, O2), I).

% 2.
-possible(put_down(A, O, S), I) :- not holds(in_hand(A, O), I).

% 3.
-possible(go_to(A, S), I) :- holds(on(A, S), I).

% 4.
-possible(pick_up(A, O), I) :- holds(on(O2, O), I).

% 5.
-possible(go_to(A, S), I) :- holds(on(O, S), I), #object(S). 

% 6.
-possible(put_down(A, O, S), I) :- holds(on(O2, S), I), #object(S).

% 7.
-possible(go_through(A, D, Loc2), I) :- not holds(location(A, Loc1), I),
				      not has_exit(Loc1, D),
				      not has_exit(Loc2, D).

% 8.
-possible(go_to(A, S), I) :- holds(in_hand(A2, S), I).

% 9. 
-possible(go_to(A, S), I) :- holds(z_loc(S, Z), I), 
                           holds(z_loc(A, Z2), I),
                           height(A, H),
                           Z2 - H = BASE, 
                           Z < BASE - 1.

% 10. 
-possible(go_to(A, S), I) :- holds(z_loc(S, Z), I), 
                           holds(z_loc(A, Z2), I), 
                           height(A, H), 
                           Z2 - H = BASE, 
                           Z > BASE + 1. 
                           
% 11. 
% forbid the agent from going to the same place
-possible(go_through(A, D, Loc2), I) :- holds(location(A, Loc1), I),
				      Loc1=Loc2.        
% 12.
-possible(go_to(A,S),I) :- holds(on(A,S2),I),
			 S=S2.
				      
% 13. can't go to objects in other rooms 
-possible(go_to(A, S), I) :- holds(location(A, Loc1), I),
                           holds(location(S, Loc2), I),
                           Loc1 != Loc2.

% 14. can't put objects on surfaces in other rooms
-possible(put_down(A, O, S), I) :- holds(location(A, Loc1), I),
                              holds(location(S, Loc2), I),
                              Loc1 != Loc2.

% 15. can't pick up objects in other rooms
-possible(pick_up(A, O), I) :- holds(location(A, Loc1), I),
                               holds(location(O, Loc2), I),
                               Loc1 != Loc2.
  
% 16. Impossible to put down things which aren't held
-possible(put_down(A,O,S), I) :- not holds(in_hand(A,O),I).				                         
                           
%% ------------------------------
%% Exec. conditions + affordances
%% ------------------------------                   

% 1. 
-possible(A, I) :- affordance_forbids(A, I, ID).

% 2.
% pick_up impossible if object is not within agents' reach
-possible(pick_up(A, O), I) :- not affordance_permits(pick_up(A, O), I, 11).


% 3.
% pick_up impossible for medium and heavy objects, unless
% the agent is strong.  
-possible(pick_up(A, O), I) :- has_weight(O, medium), 
                             not affordance_permits(pick_up(A, O), I, 10).

% 4.
-possible(pick_up(A, O), I) :- has_weight(O, heavy), 
                             not affordance_permits(pick_up(A, O), I, 10).

% 5.
% put_down impossible if target surface cannot support the obj. + 
% target surface is out of agents' reach. 
-possible(put_down(A, O, S), I) :- not affordance_permits(put_down(A, O, S), I, 12), 
                                not affordance_permits(put_down(A, O, S), I, 13).
                                                      
% 6. 
% go_to impossible unless target surface is within agents'
% movement range, and can support the agents' weight.
-possible(go_to(A, S), I) :- not affordance_permits(go_to(A, S), I, 14), 
                           not affordance_permits(go_to(A, S), I, 15),
                           not affordance_permits(go_to(A, S), I, 16).

% 7. 
% go_through impossible unless there's a surface within range
% of the opening + agents' height allows them to fit through
% the opening. 
-possible(go_through(A, E, L), I) :- not affordance_permits(go_through(A, E, L), I, 17), 
                                   not affordance_permits(go_through(A, E, L), I, 18), 
                                   not affordance_permits(go_through(A, E, L), I, 19).
                                   
% 8.
% Alternative to 7 and 9. go_through impossible, unless a surface 
% exists within appropriate range of the opening + 
% the surface can support the agent
% the agent can fit through the door.
%-occurs(go_through(A, Opening, L), I) :- not affordance_permits(go_to(A, S), I, 16), 
%                                         not holds(in_range(Opening, S, X), I),
%                                         not holds(in_range(S, Opening, Y), I), 
%                                         X<=1, 0<=X, Y<=1, 0<=Y,
%                                         not affordance_permits(go_through(A, E, L), I, 19).
                                         
% 9. 
% go_through impossible unless the opening is within agents' movement range (reach). 
% 26 remains the same as it was in the previous verison of the program. 
-possible(go_through(A, D, R), I) :- not affordance_permits(go_through(A, D, R), I, 26).
                                   %not affordance_permits(go_through(A, E, L), I, 19).
                             
%% AFFORDANCE AXIOMS END

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


% CWA for actions beong proposed by robot
-occurs(A, I) :- not occurs(A, I).

% CWA for actions being possible
%-possible(A, I) | possible(A,I) :- #step(I).
possible(A,I) :- not -possible(A,I). 

% CWA for hpd?
-hpd(A,I) :- not hpd(A,I).

%%---------------------------------------------------------
%%                         Planning
%%---------------------------------------------------------


success :- goal(I).
%-goal(I) :- not goal(I).

% do not allow concurrent actions
% need to allow concurrent actions - need to know what is possible at each step. 
%:- occurs(A1, I),
%   occurs(A2, I),
%   A1!=A2.

%% ------------------------
%%      History Rules
%% ------------------------

% if it occurs, and it's possible, assume it succeeded:
hpd(A,I) :- occurs(A,I), possible(A,I).
-hpd(A,I) :- -possible(A,I).
% Take what actually happened into account - no need for this here
%occurs(A, I) :- hpd(A, I). 

%
obs(F, true, I) :- holds(F,I), #inertial_fluent(F).

% Make sure observations match expectations
:- obs(F, true, I), -holds(F, I).
:- obs(F, false, I), holds(F, I).

% Initiate all inertial fluents at t=0:
is_defined(F) :- obs(F, Y, 0).
-holds(F, 0) :- #inertial_fluent(F),
		not is_defined(F), not holds(F, 0).

%holds(F, 0) | -holds(F, 0) :- #inertial_fluent(F).


% Reality check:
%-occurs(A,I) :+ occurs(A,I),
%		 not hpd(A,I).

-hpd(A,I) :- -possible(A,I),
              occurs(A,I).

%% or 
%-occurs(A,I) :- fails(A,I).
%fails(A,I) :+ -possible(A,I),
%               occurs(A,I).


%% or

%-occurs(A,I) :+ -possible(A,I),
%		 occurs(A,I).
%occurs(A,K) :+ #hypothetical_action(A),
%               K < n.

expl(A,I) :- #action(A),
             occurs(A,I),
             not hpd(A,I).
   
%% ------------------------------------------------------------
%%                   Affordance Relations
%% ------------------------------------------------------------

% 1. 
% ID #10 
affordance_permits(pick_up(A, O), I, 10) :- has_power(A, strong).

% 2. 
% Aff. permits picking up objects, if they are in the agents reach.
affordance_permits(pick_up(A, O), I, 11) :- height(A, H), height(O, HO), 
                                            holds(in_range(O, A, X), I),
                                            X < H,
                                            X >=0.


% 3.
% Aff. permits moving objects, if the target surface supports them.
affordance_permits(put_down(A, O, S), I, 12) :- holds(can_support(S, O), I).

% 4. 
% Aff. permits moving objects, if the target surface is within range of agents' reach (assumed to be the span of the agents body). 
affordance_permits(put_down(A, O, S), I, 13) :- holds(in_range(S, A, X), I),
                                               height(A, H), #vertsz(X),
                                               X < H, 
                                               X >= 0.

% 5. 
%Aff. permits going to surfaces, if they're not too high for the agent.
affordance_permits(go_to(A, S), I, 14) :- holds(z_loc(S, Z), I), 
                                          holds(z_loc(A, Z2), I), 
                                          height(A, H), 
                                          Z2 - H = BASE, 
                                          Z <= BASE + 1. 

% 6. 
% Aff. permits going to surfaces, if they're not too low for the agent.
affordance_permits(go_to(A, S), I, 15) :- holds(z_loc(S, Z), I), 
                                          holds(z_loc(A, Z2), I),
                                          height(A, H),
                                          Z2 - H = BASE, 
                                          Z >= BASE - 1.

% 7. 
% Aff. permits going to surfaces, if they can support the agent.
affordance_permits(go_to(A, S), I, 16) :- holds(can_support(S, A), I).

% 8 & 9. 
% Aff. permits going through an opening if there's a surface within 1 unit of the opening. 
affordance_permits(go_through(A, Opening, L), I, 17) :- holds(in_range(Opening, S, X), I), 
                                                        has_surf(S, true),
                                                        X<=1, 0<=X. 

affordance_permits(go_through(A, Opening, L), I, 18) :- holds(in_range(S, Opening, X), I), 
                                                        has_surf(S, true),
                                                        X<=1, 0<=X. 

% 10. Aff. permits going through openings that the agent can fit through.
affordance_permits(go_through(A, E, L), I, 19) :- height(A, H), 
                                                  height(E, H_exit),
                                                  H <= H_exit.

% 11.
% ID #26 Aff. permits going through openings that are within agents' movement range (assumed to be equal to agents' height).
affordance_permits(go_through(A, D, L), I, 26) :- holds(on(A, S), I),
                                                  height(A, HA),
                                                  height(D, HD),
                                                  height(S, HS),
                                                  holds(in_range(D, S, X), I), 
                                                  HS + HA > X,
                                                  HS < X + HD.
                                                  %affordance_permits(go_to(A, S), I, 16)                                    

%% --------------------------
%%         HISTORY
%% --------------------------


occurs(pick_up(robot,box1),0). 
occurs(go_through(robot,door,corridor),1).
occurs(pick_up(robot,cup),2).
occurs(put_down(robot,cup,floor),3).
occurs(pick_up(robot,box5),4).


%%------------------
%% Initial Condition
%%------------------

has_exit(room, door).
has_exit(corridor, door).

material(box1, paper).
material(box2, wood).
material(box3, wood).
material(box4, wood).
material(box5, wood).
material(floor, wood).

has_surf(box1, true).
has_surf(box2, true).
has_surf(box3, true).
has_surf(box4, true).
has_surf(box5, true).
has_surf(floor, true).
has_surf(cup, false).
has_surf(door, false).


has_weight(box1, light).
has_weight(box2, medium).
has_weight(box3, medium).
has_weight(box4, heavy).
has_weight(box5, medium).
has_weight(robot, medium). 
has_weight(cup, light).

has_power(robot, strong). 


height(robot, 2).
height(floor, 0).

height(box1, 1). 
height(box2, 1). 
height(box3, 1).
height(box4, 3).
height(box5, 1).
height(door, 3).
height(cup, 1).


holds(z_loc(floor,0),0).
holds(z_loc(door,7),0).


holds(on(box1,floor),0). 
holds(on(box2,floor),0). 
holds(on(box3,floor),0).
holds(on(box4,floor),0). 
holds(on(box5,floor),0).
holds(on(robot,floor),0).

holds(location(robot, room),0).
holds(location(box1, room), 0).
holds(location(box2, room), 0).
holds(location(box3, room), 0).
holds(location(box4, room), 0).
holds(location(box5, corridor), 0).
holds(location(cup, corridor), 0).
holds(on(cup, box5), 0).


% Execution Goal
goal(I) :- holds(in_hand(robot, box5), I).


display

success.
%-goal.
%occurs.
hpd.
obs.
%-obs.
%-hpd.
expl.
%-occurs.
%affordance_permits. 
%holds.


