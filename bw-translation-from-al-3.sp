%% --------------------------------------------
%% BW domain
%% Translation from Action Language Description
%% of the domain layout including some of the 
%% available object & agent properties, actions, 
%% a simple planning module, affordance relations
%% and their corresponding executability conditions. 
%%
%% This Script includes some affordance relations
%% similar to the previous versions of the program.
%% The representation of these has been altered to 
%% include several simple affordances in a single
%% executability condition. Some relations from the
%% previous program version have been discarded.
%% 
%% --------------------------------------------

#const n=9.

sorts

%&%& Sorts:

#area = {room, corridor}. 
#exit = {door}. 

#agent = {robot}.  %, human}.
#fixed_element = {floor, door}.
#object = {box1, box2, box3, box4, box5, box6, chair, cup}.
#thing = #object + #agent.

#obj_w_zloc = #thing + #fixed_element.

#vertsz = 0..15.
#step = 0..n.
#id = 10..40.
#bool = {true, false}.

%% VARIABLE PARAMETERS
#substance = {paper, cardboard, wood, glass}.
#power = {weak, strong}.
#weight = {light, medium, heavy}.

#skill_level = {poor, average, good}.
#limb = {arm, leg}.


%&%& Sorts: end

%%--------
%% Fluents
%%--------

#inertial_fluent = on(#thing(X), #obj_w_zloc(Y)):X!=Y +
		   z_loc(#obj_w_zloc(X), #vertsz(Z)) + 
		   location(#thing(X), #area(A)) + 
		   in_hand(#agent(A), #object(O)).

#defined_fluent = in_range(#obj_w_zloc(X), #obj_w_zloc(Y), #vertsz):X!=Y + 
		  can_support(#obj_w_zloc(X), #thing(Y)):X!=Y.

#fluent = #inertial_fluent + #defined_fluent.

%%--------
%% Actions 
%%--------


#action = go_to(#agent(A), #obj_w_zloc(S)) +
          put_down(#agent(A), #object(X), #obj_w_zloc(Y)):X!=Y +
          go_through(#agent(A), #exit(E), #area(Ar)) +
          pick_up(#agent(A), #object(O)).   
          
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

joint_mobility(#agent, #limb, #skill_level).
limb_strength(#agent, #limb, #skill_level).

has_exit(#area, #exit). 

% affordance predicates
affordance_permits(#action, #step, #id).
affordance_forbids(#action, #step, #id).

% planning: not in the original AL description.
success().
goal(#step). 
something_happened(#step).
plan_length(#step).

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
holds(on(O, S), I+1) :- occurs(put_down(A, O, S), I).

% 3. 
-holds(in_hand(A, O), I+1) :- occurs(put_down(A, O, S), I).

% 4. 
holds(z_loc(A, Z+H), I+1) :- occurs(go_to(A, S), I),
			     height(A, H), 
			     holds(z_loc(S, Z), I). 

% 5. 
holds(location(A, L), I+1) :- occurs(go_through(A, D, L), I).

% 6. 
% Assume agent ends up on the floor if location is changed
holds(on(A, floor), I+1) :- occurs(go_through(A, D, L), I).

% 7. 
holds(z_loc(O, Z+H), I+1) :- occurs(put_down(A, O, S), I),  
			     holds(z_loc(S, Z), I), 
			     height(O, H).

% 8.
holds(in_hand(A, O), I+1) :- occurs(pick_up(A, O), I).

% 9.
-holds(on(O, S), I+1) :- occurs(pick_up(A, O), I),
			 holds(on(O, S), I).

% 10. 
-holds(z_loc(O, Z), I+1) :- occurs(pick_up(A, O), I), 
			    holds(z_loc(O, Z), I).

% 11.
-holds(on(A, S), I+1) :- occurs(go_to(A, S2), I),
			 holds(on(A, S), I). 

% 12. go_to cancels z_loc, if the target surface is at a different height than starting surface
-holds(z_loc(A, Z), I+1) :- occurs(go_to(A, S), I), 
			    holds(z_loc(S, Z), I),
			    holds(on(A,S2),I),
			    holds(z_loc(S2,Z2),I),
			    Z2!=Z.

% 13. Go thorugh removes the agent from the surface they were standing on.
-holds(on(A, S), I+1) :- occurs(go_through(A, D, L), I),
			 holds(on(A,S),I).

% go through causes NOT location
%-holds(location(A, L), I+1) :- occurs(go_through(A, D, L2), I), holds(location(A,L),I), L2!=L.

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
 
% 4. height and weight have unique values
-height(O, H2) :- height(O, H), H!=H2.
-has_weight(O,W) :- has_weight(O,W2), W!=W2.
-limb_strength(A,L,V) :- limb_strength(A,L,V2), V!=V2.

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
holds(can_support(S, O), I) :- has_weight(O, light),
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
-occurs(pick_up(A, O), I) :- holds(in_hand(A, O2), I).

% 2.
-occurs(put_down(A, O, S), I) :- not holds(in_hand(A, O), I).

% 3.
-occurs(go_to(A, S), I) :- holds(on(A, S), I).

% 4.
-occurs(pick_up(A, O), I) :- holds(on(O2, O), I).

% 5.
-occurs(go_to(A, S), I) :- holds(on(O, S), I), #object(S). 

% 6.
-occurs(put_down(A, O, S), I) :- holds(on(O2, S), I), #object(S).

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
                           
% 11. 
% forbid the agent from going to the same place
-occurs(go_through(A, D, Loc2), I) :- holds(location(A, Loc1), I),
				      Loc1=Loc2.        
% 12.
-occurs(go_to(A,S),I) :- holds(on(A,S2),I),
			 S=S2.
				      
% 13. can't go to objects in other rooms 
-occurs(go_to(A, S), I) :- holds(location(A, Loc1), I),
                           holds(location(S, Loc2), I),
                           Loc1 != Loc2.

% 14. can't put objects on surfaces in other rooms
-occurs(put_down(A, O, S), I) :- holds(location(A, Loc1), I),
                              holds(location(S, Loc2), I),
                              Loc1 != Loc2, #object(S).

% 15. can't pick up objects in other rooms
-occurs(pick_up(A, O), I) :- holds(location(A, Loc1), I),
                             holds(location(O, Loc2), I),
                             Loc1 != Loc2.
% 16. can't go to agents
-occurs(go_to(A,S),I) :- #agent(S).

% 17. can't pick up objects larger than oneself
%-occurs(pick_up(A,O),I) :- height(A,H), height(O,HO), HO>=H.				                         
                           
%% ------------------------------
%% Exec. conditions + affordances
%% ------------------------------                   
%&%& E.c.:

% 1. Impossible to execute actions prevented by forbidding affrodances
-occurs(A, I) :- affordance_forbids(A, I, ID).

% 2. Impossible to go to surfaces which don't support the agent. [executability condition]
-occurs(go_to(A,S),I) :- not affordance_permits(go_to(A, S), I, 30).

% 3. Impossible to pick up objects above the agent unless it's no higher than 1 unit out of their reach...
-occurs(pick_up(A, O), I) :- holds(in_range(O,A,X),I), height(A,H), 
			     X>=H,
			     not affordance_permits(pick_up(A,O),I,17).

% 4.
% ... IF agent arms have good mobility AND appropriate strength.
-occurs(pick_up(A, O), I) :- holds(in_range(O,A,X),I), height(A,H), 
			     X>=H, 
			     affordance_permits(pick_up(A,O),I,17),
			     not affordance_permits(pick_up(A,O),I,13),
			     not affordance_permits(pick_up(A,O),I,14).

% 5.
% pick_up impossible if object is below the agent UNLESS their legs have good mobility AND it's not lower than 1 unit out of their reach.
-occurs(pick_up(A, O), I) :- holds(z_loc(A,Z),I), height(A,H), holds(z_loc(O,ZO),I), Z-H>=ZO,
			     not affordance_permits(pick_up(A,O),I,18).

% 6. ...and their arms have appropriate mobility  			     
-occurs(pick_up(A, O), I) :- holds(z_loc(A,Z),I), height(A,H), holds(z_loc(O,ZO),I), Z-H>=ZO,
			     affordance_permits(pick_up(A,O),I,18),
			     not affordance_permits(pick_up(A,O),I,15),
			     not affordance_permits(pick_up(A,O),I,16).

% 7. can't pick up objects larger than oneself unless they're light			     
-occurs(pick_up(A, O), I) :- height(A,H), height(O, HO), HO>=H,
			     not affordance_permits(pick_up(A,O),I,19).
			     
			     
% similar constraints apply to putting objects down:
% 8. can't put down objects on surfaces out of reach unless they're no more than 2 units higher
-occurs(put_down(A,O,S),I) :- holds(z_loc(A,Z),I), holds(z_loc(S,ZS),I),ZS>=Z,			       
			      not affordance_permits(put_down(A,O),I,20).	

% 9. ...and the agent has appropriate arm mobility / object isn't too heavy for the agent...
-occurs(put_down(A,O,S),I) :- holds(z_loc(A,Z),I), holds(z_loc(S,ZS),I),ZS>=Z,			       
			      affordance_permits(put_down(A,O,S),I,20),
			      not affordance_permits(pick_up(A,O),I,13),
			      not affordance_permits(pick_up(A,O),I,14). 

% 10. can't put down objects on surfaces out of reach unless they're no more than 2 units lower
% OR the object isn't heavier than than the surface & object isn't heavy.
-occurs(put_down(A,O,S),I) :- holds(z_loc(A,Z),I), holds(z_loc(S,ZS),I), height(A,H),Z-H>ZS,			       
			      not affordance_permits(put_down(A,O,S),I,21),
                              not affordance_permits(put_down(A,O,S),I,22),
                              not affordance_permits(put_down(A,O,S),I,23).	

% 11. ...and the agent has appropriate arm mobility / object isn't too heavy for the agent...
-occurs(put_down(A,O,S),I) :- holds(z_loc(A,Z),I), holds(z_loc(S,ZS),I),ZS>=Z,			       
			      affordance_permits(put_down(A,O,S),I,21),
			      not affordance_permits(pick_up(A,O),I,15),
			      not affordance_permits(pick_up(A,O),I,16). 	     
			       			  			     



% 12.
% put down impossible UNLESS target surface can support the obj.
-occurs(put_down(A, O, S), I) :- not affordance_permits(put_down(A, O, S), I, 24).
 
% 13.
% put_down impossible UNLESS target surface can support the obj. + 
% target surface is in agents' reach. 
-occurs(put_down(A, O, S), I) :- not affordance_permits(put_down(A, O, S), I, 24), 
                                 not affordance_permits(put_down(A, O, S), I, 25).
                                                      
% 14. 
% go_to an object not in range 0 is impossible UNLESS agent has pro leg mobility, target surface is within agents'
% movement range (+-1 unit).
-occurs(go_to(A, S), I) :- holds(z_loc(S,Z),I), holds(z_loc(A,Z2),I), height(A, H), Z!=Z2-H,
			   not affordance_permits(go_to(A, S), I, 28), 
                           not affordance_permits(go_to(A, S), I, 29). %,
                           %not affordance_permits(go_to(A, S), I, 20).

  
% 15. 
% go_through openings no in range 0 impossible unless there's a surface within range
% of the opening + agents' height allows them to fit through the opening. 
% 1) the surf is lower, and the agent has good leg mob. 
% 2) the surf is higher, and the agent can still fit through the opening with the remaining space
% 3) more than 1 unit if agent strong, not heavy, strong arms, can drop on other side. 
-occurs(go_through(A, D, L), I) :- holds(in_range(D,A,X),I), X!=0,
				   not affordance_permits(go_through(A, E, L), I, 31),
				   not affordance_permits(go_through(A, E, L), I, 32). 


% 16. go_through impossible unless the agents' height allows them to fit through the opening. 
-occurs(go_through(A, E, L), I) :-  not affordance_permits(go_through(A, E, L), I, 33).
                                   
                                         
% 17. 
% go_through impossible unless the opening is within agents' movement range (reach), 
% and agent has a lot of strength + isn't very heavy 
% (add in arm mobility?) 
%-occurs(go_through(A, D, R), I) :- not affordance_permits(go_through(A, D, R), I, 34).
                             


   
%% ------------------------------------------------------------
%%                   Affordance Relations
%% ------------------------------------------------------------
%&%& A.R.:
% 1. 
% ID #10 
affordance_permits(pick_up(A, O), I, 10) :- limb_strength(A, arm, good).

% 2. 
% Aff. permits picking up objects, if they are in the agents reach. +1 unit for good arm mobility
affordance_permits(pick_up(A, O), I, 11) :- height(A, H), height(O, HO), 
                                            holds(in_range(O, A, X), I),
                                            X < H,
                                            X >=0.

% 3.
% Aff. permits moving objects, if the target surface supports them.
affordance_permits(put_down(A, O, S), I, 12) :- holds(can_support(S, O), I).

% Aff. permits picking up objects within +1 unit if arm mobility
% Aff. permits picking up -1 unit if leg mobility 
% Aff. permits picking up +1 unit if arm mobility


% Impossible picking up +1-1 unit if arm/leg mobility IF object is heavy, UNLESS limb strength is good & agent is strong. 
% med-strong agents can pick up light-medium objects this way. 
% high-strength agents can pick up med-heavy objects this way. 

% 4.
% agents with flexible, agerage strength in their arms are able to pick up objects out of their range if they aren't heavy.
affordance_permits(pick_up(A,O),I,13) :- joint_mobility(A,arm,good), limb_strength(A,arm,average), not has_weight(O,heavy).

% 5.
% agents with flexible, strong arms are able to pick up objects out of their range.
affordance_permits(pick_up(A,O),I,14) :- limb_strength(A,arm,good), joint_mobility(A,arm,good).

% 6.
% agents with flexible, average strength arms and legs are able to pick up objects lower than temselves, if they aren't heavy.
affordance_permits(pick_up(A,O),I,15) :- joint_mobility(A,leg,good),limb_strength(A,leg,average), not has_weight(O,heavy),
					 joint_mobility(A,arm,good),limb_strength(A,arm,average), not has_weight(O,heavy).
% 7.
% agents with flexible, strong arms and legs are able to pick up objects lower than themselves.
affordance_permits(pick_up(A,O),I,16) :- joint_mobility(A,leg,good),limb_strength(A,leg,good),
					 limb_strength(A,arm,good), joint_mobility(A,arm,good).

% 8.
% objects out of range cannot be picked up - unless they're no more than two units higher than the agent.
affordance_permits(pick_up(A,O),I,17) :- holds(in_range(O,A,X),I), height(A,H), 
			                 X<H+2. 
% 9.
% % objects out of range cannot be picked up - unless they're no more than two units lower than the agent.
affordance_permits(pick_up(A,O),I,18) :- holds(z_loc(A,Z),I), height(A,H), holds(z_loc(O,ZO),I), 
			                 Z-H>=ZO, Z-H-ZO<2. 

% 10.
% Agents can lift objects larger than themselves, if these objects are light.
affordance_permits(pick_up(A,O),I,19) :- height(A,H), height(O, HO), HO>=H, HO<=H+1, has_weight(O,light). 

% 11.
% objects can be put on surfaces out of range - if they're no more than two units higher than the agent.
affordance_permits(put_down(A,O,S),I,20) :- holds(z_loc(A,Z),I), holds(z_loc(S,ZS),I),ZS>=Z, ZS-Z<=2.

% 12.
% objects can be put on surfaces out of range - if they're no more than two units lower than the agent.
affordance_permits(put_down(A,O,S),I,21) :- holds(z_loc(A,Z),I), holds(z_loc(S,ZS),I), height(A,H),Z-H>ZS, ZS-Z<=2.

% 13.
% objects can be put on surfaces lower than the agent can reach - if the object is light, i.e. it can be 'dropped'.
affordance_permits(put_down(A,O,S),I,22) :- holds(z_loc(A,Z),I), holds(z_loc(S,ZS),I),ZS>=Z, has_weight(O, light).

% 14.
% objects can be put on surfaces lower than the agent can reach - if the object is not heavy and the surface isn't fragile,
% i.e. it can be 'dropped' without damaging the surface.
affordance_permits(put_down(A,O,S),I,23) :- holds(z_loc(A,Z),I), holds(z_loc(S,ZS),I),ZS>=Z, has_weight(O, medium), not has_weight(S,light), not material(S,cardboard).


% 15.
% Aff. permits moving objects, if the target surface supports them.
affordance_permits(put_down(A, O, S), I, 24) :- holds(can_support(S, O), I).

% 16. 
% Aff. permits moving objects, if the target surface is within range of agents' reach (assumed to be the span of the agents body). 
affordance_permits(put_down(A, O, S), I, 25) :- height(A, H), height(S, HO),
						holds(z_loc(S,SZ),I), holds(z_loc(A,ZA),I), 
                                                ZA-H<=SZ, SZ<=ZA.


% 17. 
%Aff. permits going to surfaces within 1 unit if the agent posesses good leg mobility.
affordance_permits(go_to(A, S), I, 28) :- holds(z_loc(S, Z), I), 
                                          holds(z_loc(A, Z2), I), 
                                          height(A, H), 
                                          Z2 - H = BASE, 
                                          Z <= BASE + 1, joint_mobility(robot, leg, good).

% 18. 
% Aff. permits going to surfaces, if they're not too low for the agent and the agent posesses good leg mobility.
affordance_permits(go_to(A, S), I, 29) :- holds(z_loc(S, Z), I), 
                                          holds(z_loc(A, Z2), I),
                                          height(A, H),
                                          Z2 - H = BASE, 
                                          Z >= BASE - 1, joint_mobility(robot, leg, good).

% 19. 
% Aff. permits going to surfaces, if they can support the agent.
affordance_permits(go_to(A, S), I, 30) :- holds(can_support(S, A), I), #agent(A), #obj_w_zloc(S).

% 20 & 21. 
% Aff. permits going through an opening if there's a surface within 1 unit of the opening. if pro leg mobility Here's the error - need to have the var in the outer scope
% actually no - issues maybe arising from the fact that this is a disjuction.
% OR the range itself...
affordance_permits(go_through(A, Opening, L), I, 31) :- holds(in_range(Opening, S, X), I), 
                                                        has_surf(S, true), height(S,H), 
                                                        X=H+1,joint_mobility(robot, leg, good), holds(on(A,S),I).

affordance_permits(go_through(A, Opening, L), I, 32) :- holds(in_range(S, Opening, X), I), X>0,
							holds(z_loc(Opening,Z),I), holds(z_loc(S,ZS),I), holds(on(A,S),I), 
							height(A,H), Z-ZS>=H.

% 22. Aff. permits going through openings that the agent can fit through.
% This remains an exec. cond. unless I introduce bendiness for agents to squeeze through opening that are smaller than preferred. 
affordance_permits(go_through(A, E, L), I, 33) :- height(A, H), 
                                                  height(E, H_exit),
                                                  H <= H_exit.


% 23.
% ID #26 Aff. permits going through openings that are within agents' movement range (assumed to be equal to agents' height).
% can't go through openings that aren't at the exact same level as you unless it's within 1 unit and the agent has pro leg mobility
affordance_permits(go_through(A, D, L), I, 34) :- holds(on(A, S), I),
                                                  height(A, HA),
                                                  height(D, HD),
                                                  height(S, HS),
                                                  holds(in_range(D, S, X), I), 
                                                  HS + HA > X,
                                                  HS < X + HD.
                                                  %affordance_permits(go_to(A, S), I, 30)                                    


%%
% Forbidding affordances
affordance_forbids(pick_up(A,O),I,35) :- not has_weight(O,light), limb_strength(A,arm,poor).


                             
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


% CWA for actions
-occurs(A, I) :- not occurs(A, I).


%%---------------------------------------------------------
%%                         Planning
%%---------------------------------------------------------


success :- goal(I),
           I <= n. 
:- not success.

% an action must occur at each step
occurs(A,I) :+ #action(A).

% do not allow concurrent actions
-occurs(A2, I) :- occurs(A1, I),
   		  A1!=A2.

% forbid agents from procrastinating
something_happened(I) :- occurs(A,I).

:- not something_happened(I),
   not goal(I),
   something_happened(I+1).

plan_length(I) :- not goal(I-1), goal(I).


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
material(cup, paper).
material(chair, wood).

has_surf(box1, true).
has_surf(box2, true).
has_surf(box3, true).
has_surf(box4, true).
has_surf(box5, true).
has_surf(floor, true).
has_surf(cup, false).
has_surf(door, false).
has_surf(chair, true).

has_weight(box1, heavy).
has_weight(box2, medium).
has_weight(box3, medium).
has_weight(box4, heavy).
has_weight(box5, medium).
has_weight(robot, heavy). 
has_weight(cup, medium).
has_weight(chair, heavy).

%has_power(robot, weak). 
joint_mobility(robot, leg, poor).
limb_strength(robot, leg, good).
joint_mobility(robot, arm, good). 
limb_strength(robot, arm, good).

height(robot, 2).
height(floor, 0).
height(box1, 1). 
height(box2, 2). 
height(box3, 1).
height(box4, 3).
height(box5, 2).
height(door, 3).
height(cup, 1).
height(chair,1).

holds(z_loc(floor,0),0).
holds(z_loc(door,7),0).

holds(on(box1,floor),0). 
holds(on(box2,floor),0). 
holds(on(box3,floor),0).
holds(on(box4, floor),0). 
holds(on(box5, floor), 0).
holds(on(robot, floor),0).
%holds(on(robot, box3),0).
holds(on(cup, box5), 0).
%holds(on(chair,floor),0).
holds(on(chair,box2),0).

holds(location(robot, room),0).
%holds(location(box1, corridor), 0).
holds(location(box1, room), 0).
holds(location(box2, room), 0).
holds(location(box3, room), 0).
%holds(location(box4, corridor), 0).
holds(location(box4, room), 0).
holds(location(box5, corridor), 0).
holds(location(cup, corridor), 0).
holds(location(chair,room),0).
holds(on(cup, box5), 0).

% Goals:
%goal(I) :- holds(z_loc(robot, 4), I).
%goal(I) :- holds(z_loc(box2, 3), I).
%goal(I) :- holds(location(robot, corridor), I).
%goal(I) :- holds(on(box3, box4), I).
% Execution Goal
%goal(I) :- holds(in_hand(robot, box5), I).
%goal(I) :- holds(in_hand(robot, chair), I).
%goal(I) :- holds(in_hand(robot, cup), I).
%goal(I) :- holds(on(robot, box4), I).
%goal(I) :- holds(on(robot, floor), I).
goal(I) :- holds(on(box1, box2), I).
%goal(I) :- holds(on(box1, box2), I).
%success.

display

plan_length.
goal.
occurs.
%affordance_permits. 
%holds.


