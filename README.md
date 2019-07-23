# Box world domain

Contains scripts with a simplified version of the domain, scripts with planning modules, and scripts with affordances (in progress). 


Some of the alterations made to the logic program were conceptually significant. Thus, instead of updating the same script, different versions have been added to the repository. 

**asp_parsing.py**
Python wrapper for executing the program with a randomly generated goal. 

bw-translation-from-al-1.sp
Programs translated from action language description of the domain, with increasing complexity. Version 1 contains a plannning module, fluents, actions, and some predicates. 
Sorts and predicates relating to object and agent properties are omitted and the script doesn't contain any affordance relations. 

bw-translation-from-al-2.sp
This program contains several affordance relations which are simple, and act as executability conditions. Some additional predicates and sorts have been added. 

bw-translation-from-al-3.sp
This is the working file for the main program containing complex affordance relations. 

bw-complex-affordances.sp
An older file with an initial attempt at defining complex affordance relations. 

bwsimple.lp
A clingo version of the program bw-translation-from-al-1.sp

inert.sp
An early sketch of the domain, testing the planning module with different definitions of domain fluents 

zloc_affordances.sp
An early sketch of the domain with simple, forbidding affordance relations. 
