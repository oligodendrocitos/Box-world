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

#const n=12.

sorts

%&%& Sorts:

#area = {room, corridor}. 
#exit = {door}. 

#agent = {robot}.  %, human}.
#fixed_element = {floor, floor_cor, door}.
#object = {box1, box2, box3, box4, box5, box6, chair, cup}.
#thing = #object + #agent.

#obj_w_zloc = #thing + #fixed_element.

#vertsz = 0..15.
#step = 0..n.
#id = 10..40.
#bool = {true, false}.

%% VARIABLE PARAMETERS
#substance = {paper, plastic, wood, glass}.
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
		   location(#obj_w_zloc(X), #area(A)) + 
		   in_hand(#agent(A), #object(O)).

#defined_fluent = in_range(#obj_w_zloc(X), #obj_w_zloc(Y), #vertsz):X!=Y + 
		  can_support(#obj_w_zloc(X), #thing(Y)):X!=Y.

#fluent = #inertial_fluent + #defined_fluent.

%%--------
%% Actions 
%%--------


#action = go_to(#agent(A), #obj_w_zloc(S)) +
          put_down(#agent(A), #object(X), #obj_w_zloc(Y)):X!=Y +
          go_through(#agent(A), #exit(E), #obj_w_zloc(P)) +
          pick_up(#agent(A), #object(O)).   
          
%%-----------
%% Predicates
%%-----------

predicates

holds(#fluent, #step).
occurs(#action, #step).

height(#obj_w_zloc, #vertsz).
%has_power(#agent, #power).
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
holds(z_loc(O, Z+H), I+1) :- occurs(put_down(A, O, S), I),  
			     holds(z_loc(S, Z), I), 
			     height(O, H).

% 6.
holds(in_hand(A, O), I+1) :- occurs(pick_up(A, O), I).

% 7.
-holds(on(O, S), I+1) :- occurs(pick_up(A, O), I),
			 			holds(on(O, S), I).

% 8. 
-holds(z_loc(O, Z), I+1) :- occurs(pick_up(A, O), I), 
			    			holds(z_loc(O, Z), I).

% 9.
-holds(on(A, S), I+1) :- occurs(go_to(A, S2), I),
			 holds(on(A, S), I). 

% 10. go_to cancels z_loc, if the target surface is at a different height than starting surface
-holds(z_loc(A, ZA), I+1) :- occurs(go_to(A, S), I), 
			     holds(z_loc(S, Z), I),
			     holds(z_loc(S2,Z2),I),
			     holds(z_loc(A,ZA),I),
			     holds(on(A,S2),I),
			     Z2!=Z.


%-holds(z_loc(A, ZA), I+1) :- occurs(go_through(A, Ex, P), I), 
%			     			holds(z_loc(S, Z), I),
%			     			holds(z_loc(P,Z2),I),
%			     			holds(z_loc(A,ZA),I),
%			     			holds(on(A,S),I),
%			     			Z2!=Z.


% 11. Go thorugh removes the agent from the surface they were standing on. 
-holds(on(A, S), I+1) :- occurs(go_through(A, D, L), I),
			 holds(on(A,S),I).

% 12. go through causes NOT location
-holds(location(A, Loc), I+1) :- occurs(go_through(A, D, P), I), holds(location(A,Loc),I).

% 13. go through causes on
holds(on(A, P), I+1) :- occurs(go_through(A, D, P), I).

% 14. go through causes location change for object the agent carries
holds(location(A, Loc), I+1) :- occurs(go_through(A, D, P), I), holds(location(P,Loc),I).

% 15. things change location if brought into another room
holds(location(O,Loc2),I+1) :- occurs(go_through(A,Ex,P),I), 
			       				holds(location(P,Loc2),I),
	   			       			holds(in_hand(A,O),I).
 
% 16. things change location if brought into another room
-holds(location(O,Loc1),I+1) :- occurs(go_through(A,Ex,P),I), 
			        			holds(location(O,Loc1),I),
			        			holds(in_hand(A,O),I).

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
 
% 4. height and weight have unique values - shouldn't be needed
-height(O, H2) :- height(O, H), H!=H2.
-has_weight(O,W) :- has_weight(O,W2), W!=W2.
%-limb_strength(A,L,V) :- limb_strength(A,L,V2), V!=V2.

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
                               material(S, plastic).

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

% 13 on causes loc
holds(location(X,Loc),I) :- holds(location(Y, Loc), I),
			    holds(on(X,Y),I).

% 14 objects are in the same location as the agent holding them
holds(location(X,Loc),I) :- holds(location(Ag, Loc), I),
			    			holds(in_hand(Ag,X),I).


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
-occurs(go_through(A, D, S), I) :- not holds(location(A, Loc1), I),
				   not holds(location(S, Loc2), I),
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
-occurs(go_through(A, D, S), I) :- holds(location(A, Loc1), I), holds(location(S, Loc2),I),
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
                                 Loc1 != Loc2.

% 15. can't pick up objects in other rooms
-occurs(pick_up(A, O), I) :- holds(location(A, Loc1), I),
                             holds(location(O, Loc2), I),
                             Loc1 != Loc2.
% 16. can't go to agents
-occurs(go_to(A,S),I) :- #agent(S).

% 17. can't pick up objects larger than oneself
-occurs(pick_up(A,O),I) :- height(A,H), height(O,HO), HO>=H+2.	

% 18. sanity check rules for affordance deletion: cannot travel through openings more than 2 units away 
% out of span 
-occurs(go_through(A,E,L),I) :- holds(in_range(E,A,X),I), height(A,H), X>=H+2.
% 19. cannot travel through openings lower than the agent, 
-occurs(go_through(A,E,L),I) :- holds(in_range(A,E,X),I), height(E,H), X>=H.	

% 20 Cannot travel to stufaces out of reach 
-occurs(go_through(A,E,S),I) :- holds(z_loc(S, Z), I), 
                                holds(z_loc(E, Z2), I),
                                height(E, H),
                                Z2 - H = BASE, 
                                Z < BASE - 1.

% 21. 
-occurs(go_through(A, E, S), I) :- holds(z_loc(S, Z), I), 
                           	   holds(z_loc(E, Z2), I), 
                           	   height(E, H), 
                           	   Z2 - H = BASE, 
                                   Z > BASE + 1. 


% 22. Cannot bring object through a smaller exit/opening
-occurs(go_through(A, Ex, S),I) :- holds(in_hand(A,O),I), height(O,HO),height(Ex,HE), HO>=HE.

% 23. No agent can pick up objects more than 2 units out of reach
-occurs(pick_up(A,O),I) :- holds(in_range(O,A,X),I), height(A,H), X>H+1.
-occurs(pick_up(A,O),I) :- holds(z_loc(O,Zo),I), holds(z_loc(A,Za),I), height(A,Ha), Za-Ha-Zo>1.                       
                           
%% ------------------------------
%% Exec. conditions + affordances
%% ------------------------------                   
%&%& E.c.:

% 11. 
% Impossible to execute actions prevented by forbidding affrodances
-occurs(A, I) :- affordance_forbids(A, I, ID).

% 12. 
%Impossible to go to surfaces which don't support the agent. [executability condition]
-occurs(go_to(A,S),I) :- not affordance_permits(go_to(A, S), I, 30).


% 13. 
%Agents with flexible arms can pick up objects out of their reach... [higher]
-occurs(pick_up(A, O), I) :- holds(in_range(O,A,X),I), height(A,H), X>=H,
			     not affordance_permits(pick_up(A,O),I,13),
			     not affordance_permits(pick_up(A,O),I,14).

% 14. 
%...[lower]...
-occurs(pick_up(A, O), I) :- holds(z_loc(A,Z),I), height(A,H), holds(z_loc(O,ZO),I), Z-H>=ZO,
			     not affordance_permits(pick_up(A,O),I,13),
			     not affordance_permits(pick_up(A,O),I,14).

% 15.
% ...unless the object is lower, in which case they must also have good leg mobility. [average strength]
-occurs(pick_up(A, O), I) :- holds(z_loc(A,Z),I), height(A,H), holds(z_loc(O,ZO),I), Z-H>=ZO,
			     			 affordance_permits(pick_up(A,O),I,13),
			     			 not affordance_permits(pick_up(A,O),I,15).

% 16. 
%... [second conjunctive set for strong agents]			     
-occurs(pick_up(A, O), I) :- holds(z_loc(A,Z),I), height(A,H), holds(z_loc(O,ZO),I), Z-H>=ZO,
			     affordance_permits(pick_up(A,O),I,14),
			     not affordance_permits(pick_up(A,O),I,16).

% 17. 
%can't pick up objects larger than oneself unless they're light			     
-occurs(pick_up(A, O), I) :- height(A,H), height(O, HO), HO>=H,
			     			not affordance_permits(pick_up(A,O),I,19).
			     
			     
% 18.
% can't put objects on surfaces out of reach (higher) unless the agent has appropriate arm mobility (allowing to reuse the same skills as needed for pickup)
-occurs(put_down(A,O,S),I) :- holds(z_loc(A,Z),I), holds(z_loc(S,ZS),I),ZS>=Z,			       
			      not affordance_permits(pick_up(A,O),I,13),
			      not affordance_permits(pick_up(A,O),I,14).	


% 20. 
%can't put down objects on surfaces more than 1 unit lower, unless the objects can be 'dropped'.
-occurs(put_down(A,O,S),I) :- holds(z_loc(A,Z),I), holds(z_loc(S,ZS),I), height(A,H),Z-H>ZS,
			      			  not affordance_permits(put_down(A,O,S),I,21),								
                              not affordance_permits(put_down(A,O,S),I,22),
                              not affordance_permits(put_down(A,O,S),I,23).	

% 21. 
%if objects can't be 'droppped', only agents with flexible limbs can put them on lower surfaces 
% These agent attributes are the same as they are for picking up objects out of range:
% if agents possess these characteristics, they can also put objects down.
-occurs(put_down(A,O,S),I) :- holds(z_loc(A,Z),I), holds(z_loc(S,ZS),I),height(A,H),Z-H>ZS,			       
			      affordance_permits(put_down(A,O,S),I,21),
			      not affordance_permits(pick_up(A,O),I,15),
			      not affordance_permits(pick_up(A,O),I,16). 	     

% 22.
-occurs(put_down(A,O,S),I) :- holds(z_loc(A,Z),I), holds(z_loc(S,ZS),I),height(A,H),Z-H>ZS, 			       
			      affordance_permits(put_down(A,O,S),I,21),
			      affordance_permits(pick_up(A,O),I,15),
			      not affordance_permits(pick_up(A,O),I,13). 
% 23. 
-occurs(put_down(A,O,S),I) :- holds(z_loc(A,Z),I), holds(z_loc(S,ZS),I),height(A,H),Z-H>ZS, has_weight(O,heavy),			       
			      affordance_permits(put_down(A,O,S),I,21),
			      affordance_permits(pick_up(A,O),I,16),
			      not affordance_permits(pick_up(A,O),I,14). 			       			  			    

% 24.
% put down impossible UNLESS target surface can support the obj.
-occurs(put_down(A, O, S), I) :- not affordance_permits(put_down(A, O, S), I, 24).
 
% 25.
% put_down impossible for inflexible agents UNLESS target surface is in agents' reach. 
-occurs(put_down(A, O, S), I) :- not joint_mobility(A, arm, good), 
								 not affordance_permits(put_down(A, O, S), I, 25),
								 not affordance_permits(put_down(A, O, S), I, 22),
								 not affordance_permits(put_down(A, O, S), I, 23).
% 26.
-occurs(put_down(A, O, S), I) :- not joint_mobility(A, leg, good), 
								 not affordance_permits(put_down(A, O, S), I, 25),
								 not affordance_permits(put_down(A, O, S), I, 22),
								 not affordance_permits(put_down(A, O, S), I, 23).

% 27. 
% go_to an object not in range 0 is impossible UNLESS agent has pro leg mobility, target surface is within agents'
% movement range (+-1 unit).
-occurs(go_to(A, S), I) :- holds(z_loc(S,Z),I), holds(z_loc(A,Z2),I), height(A, H), Z!=Z2-H,
			   not affordance_permits(go_to(A, S), I, 28).

% 28. 
-occurs(go_to(A, S), I) :- holds(z_loc(S,Z),I), holds(z_loc(A,Z2),I), height(A, H), Z!=Z2-H,
			   affordance_permits(go_to(A, S), I, 28),
			   not affordance_permits(pick_up(A,O),I,15),
			   not affordance_permits(pick_up(A,O),I,16),
			   #object(O).
 
% 29. 
% go_through openings no in range 0 impossible unless there's a surface within range
% of the opening + agents' height allows them to fit through the opening. 
% 1) the surf is lower, and the agent has good leg mob. 
% 2) the surf is higher, and the agent can still fit through the opening with the remaining space
% 3) more than 1 unit if agent strong, not heavy, strong arms, can drop on other side. 
-occurs(go_through(A, Ex, P), I) :- holds(in_range(Ex,A,X),I), X!=0,
				   not affordance_permits(go_through(A, Ex, P), I, 31),
				   not affordance_permits(go_through(A, Ex, P), I, 32).


% 30.
% go_through impossible unless the agents' height allows them to fit through the opening.
% Agents can't use an opening that is smaller than them, unless their legs are flexible (i.e.
% an agent can squat or perhaps also bend their arms. This could be altered to add something 
% like torso flexibility.) This isn't otherwise constrained - the smallest exit is 1 unit high
% and agents height won't be selected above 3. 
-occurs(go_through(A, E, L), I) :-  height(A, H), height(E, H_exit), H >= H_exit,
				    not affordance_permits(pick_up(A, O), I, 15),
				    not affordance_permits(pick_up(A, O), I, 16). 
                                 
                                         
% 31. 
% go_through impossible unless the opening is within agents' movement range (reach), 
% and agent has a lot of strength 
% (add in arm mobility for climbing down to surfaces?) 
%-occurs(go_through(A, D, R), I) :- not affordance_permits(go_through(A, D, R), I, 34).
-occurs(go_through(A, Ex, P), I) :- holds(z_loc(P,Zp),I), holds(z_loc(Ex,Ze),I), height(Ex, He), Ze-He>Zp,
			            not affordance_permits(go_to(A, P), I, 28).

% 32.
-occurs(go_through(A, Ex, P), I) :- holds(z_loc(P,Zp),I), holds(z_loc(Ex,Ze),I), height(Ex, He), Ze-He>Zp,
			            affordance_permits(go_to(A, P), I, 28),
			   	    not affordance_permits(pick_up(A,O),I,15),
			   	    not affordance_permits(pick_up(A,O),I,16),
			   	    #object(O).
					
                             

%% AFFORDANCE AXIOMS END
   
%% ------------------------------------------------------------
%%                   Affordance Relations
%% ------------------------------------------------------------
%&%& A.R.:
% 10. 
% ID #10 
affordance_permits(pick_up(A, O), I, 10) :- limb_strength(A, arm, good).

% 11. 
% Aff. permits picking up objects, if they are in the agents reach. +1 unit for good arm mobility
affordance_permits(pick_up(A, O), I, 11) :- height(A, H), height(O, HO), 
                                            holds(in_range(O, A, X), I),
                                            X < H,
                                            X >=0.
% 12.
% Aff. permits moving objects, if the target surface supports them.
affordance_permits(put_down(A, O, S), I, 12) :- holds(can_support(S, O), I).

% Next
% 13.
% agents with flexible, agerage strength in their arms are able to pick up objects out of their range if they aren't heavy.
affordance_permits(pick_up(A,O),I,13) :- joint_mobility(A,arm,good), limb_strength(A,arm,average), not has_weight(O,heavy).

% Next
% 14.
% agents with flexible, strong arms are able to pick up objects out of their range.
affordance_permits(pick_up(A,O),I,14) :- limb_strength(A,arm,good), joint_mobility(A,arm,good).

% Next
% 15.
% agents with flexible, average strength arms and legs are able to pick up objects lower than temselves, if they aren't heavy. CONJUNCT WITH PREV. PICKUP AXIOMS.
affordance_permits(pick_up(A,O),I,15) :- joint_mobility(A,leg,good),limb_strength(A,leg,average).

% Next
% 16.
% agents with flexible, strong arms and legs are able to pick up objects lower than themselves. CONJUNCT WITH PREV. PICK UP AXIOMS. 
affordance_permits(pick_up(A,O),I,16) :- joint_mobility(A,leg,good),limb_strength(A,leg,good).
% these two can just be included in the - no they can't 

% 19.
% this doesn't add much.  -unless plastic boxes solve the problem!
% Agents can lift objects larger than themselves, if these objects are light.
affordance_permits(pick_up(A,O),I,19) :- height(A,H), height(O, HO), HO<=H+1, has_weight(O,light). 

% % Next
% 20.
% objects can be put on surfaces out of range - if they're no more than two units higher than the agent.
affordance_permits(put_down(A,O,S),I,20) :- holds(z_loc(A,Z),I), holds(z_loc(S,ZS),I),ZS>=Z, ZS-Z<=2.

% Next
% do these need to have the z information? 
% 21.
% objects can be put on surfaces out of range - if they're no more than two units lower than the agent.
affordance_permits(put_down(A,O,S),I,21) :- holds(z_loc(A,Z),I), holds(z_loc(S,ZS),I), height(A,H),Z-H>ZS, Z-H-ZS<2.

% Next
% 21.
% objects can be put on surfaces lower than the agent can reach - if the object is light, i.e. it can be 'dropped'.
affordance_permits(put_down(A,O,S),I,22) :- has_weight(O, light).

% 23.
% objects can be put on surfaces lower than the agent can reach - if the object is not heavy and the surface isn't fragile,
% i.e. it can be 'dropped' without damaging the surface.
affordance_permits(put_down(A,O,S),I,23) :- has_weight(O, medium), not material(S,glass), not material(O,glass).


% 24.
% Aff. permits moving objects, if the target surface supports them.
affordance_permits(put_down(A, O, S), I, 24) :- holds(can_support(S, O), I).

% 25. 
% Aff. permits moving objects, if the target surface is within range of agents' reach (assumed to be the span of the agents body). CONTRADICOTRY TO THE 'DROP' RULES ABOVE
affordance_permits(put_down(A, O, S), I, 25) :- height(A, H),
						holds(z_loc(S,SZ),I), holds(z_loc(A,ZA),I), 
                                                ZA-H<=SZ, SZ<=ZA.

% Next
% 28. 
%Aff. permits going to surfaces within 1 unit if the agent posesses good leg mobility. CONJUNCT. WITH LEG MOBILITY FROM PICK UP.
affordance_permits(go_to(A, S), I, 28) :- holds(z_loc(S, Z), I), 
                                          holds(z_loc(A, Z2), I), 
                                          height(A, H), 
                                          Z2 - H = BASE, 
                                          Z <= BASE + 1,
					  					  Z >= BASE - 1.

% 30. 
% Aff. permits going to surfaces, if they can support the agent.
affordance_permits(go_to(A, S), I, 30) :- holds(can_support(S, A), I), #agent(A), #obj_w_zloc(S).

% Next
% 31 & ... 
% Aff. permits going through an opening if there's a surface within 1 unit of the opening. if pro leg mobility Here's the error - need to have the var in the outer scope
% actually no - issues maybe arising from the fact that this is a disjuction.
% OR the range itself...
affordance_permits(go_through(A, Opening, P), I, 31) :- holds(in_range(Opening, S, X), I), 
                                                        has_surf(S, true), height(S,H),
							X=H+1, holds(on(A,S),I). 

% Next                                                        
% 32. 
affordance_permits(go_through(A, Opening, P), I, 32) :- holds(in_range(S, Opening, X), I), X>0,
							holds(z_loc(Opening,Z),I), holds(z_loc(S,ZS),I), holds(on(A,S),I), 
							height(A,H), Z-ZS>=H.


% 33. 
% Aff. permits going through openings that the agent can fit through.
% This remains an exec. cond. unless I introduce bendiness for agents to squeeze through opening that are smaller than preferred. 
%affordance_permits(go_through(A, E, P), I, 33) :- height(A, H), 
%                                                  height(E, H_exit),
%                                                  H <= H_exit.
% Agents whose limbs (or just legs?) are flexible can also go through smaller openings - i.e. they can 'squat' and this can be taken from pick up?                            


%%
% Forbidding affordances
affordance_forbids(pick_up(A,O),I,35) :- not has_weight(O,light), limb_strength(A,arm,poor).


                             
%&%& A.R. end



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
occurs(A,I) :+ not goal(I).

% do not allow concurrent actions
-occurs(A2, I) :- occurs(A1, I),
   		  A1!=A2.

% forbid agents from procrastinating
something_happened(I) :- occurs(A,I).

:- not something_happened(I),
   not goal(I),
   something_happened(I+1).

plan_length(I) :- not goal(I-1), goal(I).

plan_length(0) :- goal(0).


%%------------------
%% Initial Condition
%%------------------

%joint_mobility(robot, leg, good).
%limb_strength(robot, leg, average).
%joint_mobility(robot, arm, good).
%limb_strength(robot, arm, good).
has_exit(corridor,door).
has_exit(room,door).
%&%& Received initial condition:



material(floor,wood). 
material(box4,wood). 
material(box3,wood). 
material(box5,wood). 
material(box6,plastic). 
material(floor_cor,wood). 

has_weight(box1,light). 
has_weight(box3,medium). 
has_weight(box4,medium). 
has_weight(box5,medium). 
has_weight(box6,light). 
has_weight(cup,light). 
height(floor,0). 
height(cup,1). 
height(chair,1). 
height(box1,1). 
height(box2,1). 
height(box4,3). 
height(box6,1). 
height(robot,2). 
height(floor_cor,0). 
limb_strength(robot,leg,good). 
limb_strength(robot,arm,good). 
has_surf(box1,true). 
has_surf(box2,true). 
has_surf(box3,true). 
has_surf(box4,true). 
has_surf(box5,true). 
has_surf(box6,true). 
has_surf(floor,true). 
has_surf(cup,false). 
has_surf(chair,true). 
has_surf(door,false). 
has_surf(robot,false). 
has_surf(floor_cor,true). 
joint_mobility(robot,leg,good). 
joint_mobility(robot,arm,good). 
holds(z_loc(floor,0),0). 
holds(z_loc(door,6),0). 
holds(on(box3,floor),0). 
holds(on(box4,floor),0). 
holds(on(box5,floor_cor),0). 
holds(on(cup,floor_cor),0). 
holds(location(robot,room),0). 
holds(location(box1,room),0). 
holds(location(box2,room),0). 
holds(location(box3,room),0). 
holds(location(box4,room),0). 
holds(location(chair,room),0). 
holds(location(cup,corridor),0). 
holds(location(box5,corridor),0). 
holds(location(floor_cor,corridor),0). 
holds(location(floor,room),0). 
holds(z_loc(floor_cor,0),0). 
holds(z_loc(cup,1),0). 
holds(z_loc(box4,3),0). 
holds(z_loc(box5,2),0). 
holds(z_loc(box6,1),0). 
holds(z_loc(box3,2),0). 
holds(z_loc(chair,1),0). 
holds(z_loc(box1,1),0). 
holds(z_loc(robot,2),0). 
holds(z_loc(box2,3),0). 
holds(on(chair,floor),0). 
holds(on(box1,floor),0). 
holds(on(box2,box3),0). 
holds(on(robot,floor),0). 
holds(on(box6,floor),0). 
holds(location(box6,room),0). 
height(door,3). 
height(box5,2). 
height(box3,2). 
has_weight(chair,medium). 
has_weight(robot,medium). 
has_weight(box2,heavy). 
material(box1,glass). 
material(cup,paper). 
material(box2,wood). 
material(chair,wood).

%&%& End of starting state

% Goals:
%goal(I) :- holds(z_loc(robot, 4), I).
%goal(I) :- holds(z_loc(box2, 3), I).
%goal(I) :- holds(location(robot, corridor), I).
%goal(I) :- holds(on(box3, box4), I).
% Execution Goal
%goal(I) :- holds(in_hand(robot, box5), I).
%goal(I) :- holds(in_hand(robot, box2), I).
%goal(I) :- holds(in_hand(robot, cup), I).%
%goal(I) :- holds(on(robot, box5), I).
%goal(I) :- holds(on(robot, floor), I).
%goal(I) :- holds(on(chair, floor), I).
%goal(I):-holds(on(cup,box6),I).
%goal(I) :- holds(on(box1, box2), I).
%goal(I) :- holds(on(box1, floor_cor), I).
%goal(I) :- holds(z_loc(robot, 0),I).
%goal(I):-holds(on(cup,box1),I).
%success.

display

success.
plan_length.
goal.
occurs.
%affordance_permits. 
%holds.


