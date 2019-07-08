#const n=10.

%%%%%%%%%%%%%
%%% SORTS %%%
%%%%%%%%%%%%%

sorts

#area = {room, corridor}.				% enclosed space
#exit = {door}.						% an opening
#box = {box1, box2, box3, box4, box5}.			% defined as a sort for convenience (assume a rect. shape+surf.properties)
#other = {apple}.					% other objects in the domain
#agent = {robot, human, ghengis}.			% entities that perceive and act

#fixed_element = {floor, door}.				% things that don't change their coordinates (e.g. architecture)
#object = #box + #other.				% things that can be acted upon by agents
#thing = #object + #agent. 				% things that are mobile
#surf = #box + {floor}.					% things that have a surface
#obj_w_zloc = #thing + #fixed_element.			% things that have a 3d location / coordinates 

%% Properties
#vertsz = 0..18. 					% units of length/distance
#weight = {light, medium, heavy}.			% levels of weight
#substance = {paper, wood, cardboard, bio}.	        % substance objects are made of 
#power = {weak, strong}. 				% agents' capacity to exert force

#step = 0..n.						% time indices
#id = 10..31.						% affordance identifiers
#bool = {true, false}.					% boolean values for hpd, or fluents

%%%%%%%%%%%%%%%
%%% fluents %%%
%%%%%%%%%%%%%%%

% TODO: 
% 1. change z_loc to z_c 
% 2. add coordinates X,Y,Z, e.g. loc(thing, x_c, y_c, z_c)
% 3. get rid of #surf add has_surf(thing, bool) instead
% 4. add a fluent for distance between objects (if using the method from Sindlar&Meyer)
% 5. change can support to an affordance
% 6. add has_arms(agent, bool) - ghengis shouldn't be able to lift or move anything
% 7. add exec. cond. for going to surfaces much higher/lower than the agent i.e. incorporate their mobility

#inertial_fluent = on(#thing(X), #surf(Y)):X!=Y + z_loc(#obj_w_zloc, #vertsz) + location(#thing, #area) + in_hand(#agent, #object).

#def_fluent = in_range(#obj_w_zloc, #obj_w_zloc, #vertsz) + can_support(#surf, #thing).

#fluent = #inertial_fluent +#def_fluent.

%%%%%%%%%%%%%%%
%%% actions %%%
%%%%%%%%%%%%%%%

#action = go_to(#agent, #surf) +
          move_to(#agent, #object(X), #surf(Y)):X!=Y+
          go_through(#agent, #exit, #area) +
          pick_up(#agent, #object). 

% go through includes the target location as it's the easiest way for me to specify this action without additional changes



%%%%%%%%%%%%%%%%%%
%%% PREDICATES %%%
%%%%%%%%%%%%%%%%%%
predicates

% Properties
height(#obj_w_zloc, #vertsz).
has_power(#agent, #power).
has_weight(#thing, #weight).
material(#surf, #substance).
has_exit(#area, #exit).

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

% Agent R going through exit D that leads to L, 
% causes agent to change its' location to L.
holds(location(R,L),I+1) :- occurs(go_through(R,D,L),I).

% pick_up causes in_hand 
holds(in_hand(R,O), I+1) :- occurs(pick_up(R,O),I).


% Because z_loc is an inertial fluent, it requires
% explicit rules negating the previous z_loc everytime 
% it changes. 

% pick_up negates an objects location.
-holds(on(O,S),I+1) :- occurs(pick_up(R,O),I), 
                       holds(on(O,S),I). 

-holds(z_loc(O,Z),I+1) :- occurs(pick_up(R,O),I), 
                          holds(z_loc(O,Z),I). 

% go_to causes an agent to change its location
-holds(on(A,S),I+1) :- occurs(go_to(A,S2),I), 
                       holds(on(A,S),I).

% moving causes z coordinates to change 
-holds(z_loc(R,Z),I+1) :- occurs(go_to(R,S),I),
                          holds(z_loc(R,Z),I).
% !! This may cause an issue if moving to a place on the same height as before. 
% This should be a defined fluent.
% ALternatively, add a condition about on(A,S2), and test for equality between z_loc(S2==S)



%%%%%%%%%%%%%%%%%%%
% State Constraints

% two things can't be on the same surface, unless this surface is the floor
-holds(on(O,S),T) :- holds(on(O2,S),T),
                     #box(S),
                     O!=O2.

% Z coordinates are determined by an objects height and the location of the surface it is on
holds(z_loc(O,L+H),I) :- holds(on(O,S),I),
                         height(O,H),
                         holds(z_loc(S,L),I).


% In range specifies location of one object w.r.t. another
% Range is a number (of sort #vertsz). Numbers in .sp must be non-negative,
% so OB0 must be higher, or on the same level as OB1.
% X therefore denotes how much higher the base of OB0 is 
% w.r.t. the base of OB1. 
% For example, if OB0 and OB1 are on the same surface, X=0;
% if OB0 is on a surface 1 unit higher than the bottom surface of OB1, X=1.
% The bottom surface is used because objects and agents have varying height.
% Using z_loc (top surface coordinates) would require more arithmetic when 
% defining action capabilities of specific agents. 
holds(in_range(OB0,OB1,X),I) :- holds(z_loc(OB0,Z0),I),
                                holds(z_loc(OB1,Z1),I),
				height(OB0,H0), height(OB1, H1),
				(Z0-H0)>=(Z1-H1),
                       	        X = (Z0-H0)-(Z1-H1).
                          
% object can only be on one surface at a time
-holds(on(O, S), T) :- #thing(O), holds(on(O, S2), T), S!=S2.

% things can be in only one room at a time. This shouldn't be necessary. 
-holds(location(X,L),I) :- holds(location(X,L2),I), L!=L2.

% squishy things (biological materials), cardboard cannot support heavy objects.
holds(can_support(S,O),I) :- has_weight(O,light), material(S,bio).
holds(can_support(S,O),I) :- not has_weight(O,heavy), material(S,cardboard).
holds(can_support(S,O),I) :- not has_weight(O,heavy), material(S,paper).
holds(can_support(S,O),I) :- material(S,wood). % assume wood can support anything
% an object cannot suport another if it's on top of something that also doesn't support the object. 
-holds(can_support(S,O),I) :- holds(on(S,S2),I),
               		      not holds(can_support(S2,O),I).

% it's defined, thus everyhitng else should not be able to support 
% the object because of CWA.  

% this also means that affordances for agents going to surfaces is redundant...

%%%%%%%%%%%%%%%%%%%%%%%%%%
% Executability Conditions

-occurs(pick_up(R,O),I) :- holds(in_hand(R,O1),I).

% can't move object not currently holding
-occurs(move_to(R,O,S),I) :- not holds(in_hand(R,O),I).

% can't move things on top of things in someone's hand
-occurs(move_to(A,O,S),I) :- holds(in_hand(A2,S),I).

% Going to / moving to the current location results in nothing
-occurs(go_to(R,S),I) :- holds(on(R,S),I).

% go_to object not possible if another agent is holding the object                                
-occurs(go_to(A,S),I) :- holds(in_hand(A2,S),I).

% an object can't be picked_up if something's on top of it
-occurs(pick_up(R,O),I) :- holds(on(O2, O), I).

% not possible to move/go_to an occupied location
-occurs(go_to(R,O),I) :- holds(on(O2, O), I),
                         #box(O).

% not possible to move/go_to an occupied location
-occurs(move_to(R,O,S),I) :- holds(on(O2, S), I),
                             #box(S).

% go_through possible only if the exit is in the area the agent is in
% and only if the exit D connects the current location to the target L2
-occurs(go_through(R,D,L2),I) :- not holds(location(R,L1),I),	
                                 not has_exit(L1,D),
                                 not has_exit(L2,D).

% move_to is possible unless the target surface doesn't support the object. 
-occurs(move_to(A,O,S),I) :- not holds(can_support(S,O),I).

% go_to impossible to a surface that cannot support the agent:
-occurs(go_to(A,S),I) :- not holds(can_support(S,A),I). 



% Affordance rules and executability conditions:

% general affordance rules
% all forbidding affordances act similar to exec. conditions.
-occurs(A,I) :- affordance_forbids(A,I,ID).

% objects that aren't in range cannot be picked up. There are no agent properties I can add to this rule. 
-occurs(pick_up(R,O),I) :- not affordance_permits(pick_up(R,O),I,17). 

% agents can't go through openings that are not in range. Can't add agent properties to this rule.  
-occurs(go_through(A,D,R),I) :- not affordance_permits(go_through(A,D,R),I,26).

-occurs(pick_up(R,O),I) :- has_weight(O,heavy), not affordance_permits(pick_up(R,O),I,10).
-occurs(pick_up(R,O),I) :- has_weight(O,medium), not affordance_permits(pick_up(R,O),I,10).


% things more than 1 unit lower than agents feet:

-occurs(go_to(A, S), I) :- holds(z_loc(S,Z),I), 
                           holds(z_loc(A,Z2),I),
		            height(A,H),
  			    Z2-H = BASE,
                           Z < BASE-1. 
                           
-occurs(go_to(A, S), I) :- holds(z_loc(S,Z),I), 
                           holds(z_loc(A,Z2),I),
		            height(A,H),
  			    Z2-H = BASE, 
                           Z > BASE + 1.

					   
%%%%%%%%%%%%%%%%					   
% Inertia Axiom: 

holds(F, I+1) :- #inertial_fluent(F),
		holds(F, I),
		not -holds(F, I+1).

-holds(F, I+1) :- #inertial_fluent(F),
		 -holds(F, I),
		 not holds(F, I+1). 


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

% forbid agents from procrastinating
something_happened(I) :- occurs(A,I).

:- not something_happened(I),
   something_happened(I+1).

:- goal(I), goal(I-1),
   J < I,
   not something_happened(J).

%%%%%%%%%%%%%%%       
%%% History %%%
%%%%%%%%%%%%%%%

% actions
% add exogenous actions - if hpd(A,I) is not observed,
% but some fluent is observed to change its value,
% then use a cr rule to assume an action happened -
% this can't be inlcuded here because I already have an inconsistency 
% that's driving the planning.

% if an action is observed, assume it has occured
occurs(A,I) :- hpd(A,I).

% check for contradictions
:- obs(F, true, I), -holds(F, I).
:- obs(F, false, I), holds(F, I).

% state at t=0
holds(F,0) :- obs(F, B, 0).
-holds(F, 0) :- #inertial_fluent(F), not holds(F, 0).



%%%%%%%%%%%%%%%%%%%
%%% Affordances %%%
%%%%%%%%%%%%%%%%%%%

% Affordance permits: in general, things are not possible unless a particular agent-object property combination holds.
% Unfortunately, this isn't always easy to set up in this domain, as the head does not have information that would be
% needed to determine whether the rule applies: 
% relation 10 has R in the head and the body, and so can be used in the statement 
% -occurs(X(R, Y)) :- not(aff_permits(X, R, 10), heavy(O). (not syntactically precise)
% whereas relations like 17 include only R, O in their head, but other parameters such as S, X, H, HO etc.
% which determines when the relation holds. This can't be separated into components like rule 10.


affordance_permits(pick_up(R,O), I, 10) :- has_power(R, strong).

% Exec. Cond. 
% affordance permits picking up objects that are in agents' range of reach. 
% if X=0, object is at agents' 'feet'; 
% if X=H (agents' height), the object is above the agent (and thus can't be picked up).
% This can't be rewritten in a way as the 10th rule, because I have no idea what to put in the exec. condition.
% -occurs(pick_up()I), :- not affordance_permits(pick_up(), I, 17), agent/object property-????.
affordance_permits(pick_up(R,O), I, 17) :- height(R,H), height(O,HO),
                                           holds(in_range(O,R,X),I),
					   X<H,
					   X>=0.
% It's not feasible to only keep height in this rule to make it similar to the rule above. 

% General Case I
% permits pick_up if there's a surface from which an object can be reached by the agent:
% if X=0, the base of the object starts at the same level as the surface. 
% in this case 
% if X-height(surf)=0, the object would be at agents' 'feet'.
% if X-height(surf)>=height(agent), then the object would be above the agent.  
affordance_permits(pick_up(R,O), I, 23) :- affordance_permits(go_to(R,S), I, ID),
                                           holds(in_range(O, S, X),I),
					   height(R,H), height(S,HS), height(O,HO),
					   X>=0+HS,X<H+HS.
% N.B.: there's an executability condition in the head of the above rule (ID includes 21 & 22). 
% I'm not sure whether it would result in nonsense if this is changed to the general case. 
																					 
										  				   
% General Case										   
% permits go_through if there's a surface from which the exit can be reached by the agent 
% AND it's possible for the agent to go to this surface.
% Height of surf and agent need to be at least X, otherwise the door is above the agent;
% Height of surf needs to be smaller than X and the object height, otherwise the door is below the agent.
% This is used as an affordance (general case)
affordance_permits(go_through(R,D,L), I, 25) :- affordance_permits(go_to(R,S), I, ID),
                                                height(R,HR), height(D, HD), height(S,HS),
                                                holds(in_range(D, S, X),I),
						HS+HR>X,
						HS<X+HD.
																																							
% Exec. Cond. 
% permits go through if door is within agents' reach
% Statements as above. 
affordance_permits(go_through(R,D,L), I, 26) :- holds(on(R,S),I),
						height(R,HR), height(D, HD), height(S,HS),
                                                holds(in_range(D, S, X),I),
						HS+HR>X,
						HS<X+HD.

%affordance_permits(go_to(A, S), I, 27) :- holds(z_loc(S,Z),I), 
%                         		   holds(z_loc(A,Z2),I),
%		            		   height(A,H),
%  			    		   Z2-H= BASE,
%                           		   Z > BASE-1, 
%                           		   Z < BASE+1.


%%%%%%%%%%%%%%
%%% GROUND %%%
%%%%%%%%%%%%%%

% Test I: There's stuff an agent can move, but cannot stand on
% Test II: There's stuff an agent can stand on, but can't move (really this needs x&y coordinates unless all of them are heavy and the human doesn't help)
% Test III: There's stuff an agent can move and stand on, but not enough to reach the target. 
% If no goal is set, and actions are available, it it should be able to infer whether an agent can exit the room based on agent properties.  

has_exit(room, door).
has_exit(corridor, door).

has_weight(robot, heavy).
has_weight(human, heavy).
has_weight(box1, light).
has_weight(box2, medium).
has_weight(box3, medium).
has_weight(apple, light).
has_weight(box5, medium).

has_power(robot, strong).
has_power(ghengis, weak).
has_power(human, strong).

material(box1,paper).
%material(box2,paper).
material(box2,wood).
material(box3,wood).
material(box4,wood).
material(box5,wood).
material(floor,wood).
%material(apple,bio). sorts need to be altered first


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


% as floor is an independent object, just add this to make sure it's not causing trouble
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
holds(location(ghengis, room),0).

%goal(I) :- holds(z_loc(robot,5), I). % this should be impossible with two wooden and one paper box if robot height is 2

%goal(I) :- holds(location(robot,corridor), I), holds(location(human, corridor),I). 
%goal(I) :- holds(location(human, corridor),I). 
goal(I) :- holds(location(robot,corridor), I). % N.B. if apple is on box4, this needs >6 iterations
%goal(I) :- holds(on(robot,box4), I).  
%goal(I) :- holds(in_hand(robot,box1), I). 
%goal(I) :- holds(on(box1, box2), I). 
%goal(I) :- holds(in_hand(robot, apple),I).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
display
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
occurs.
goal.
%holds.
%-holds.
%affordance_permits.
%affordance_forbids.