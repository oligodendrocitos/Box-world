##  asp_parsing.py
##
##  /usr/bin/python2.7
##

import os
# import subprocess
from subprocess import Popen, PIPE
from subprocess import *
import re
import random
import time
import numpy as np
import csv
#import cPickle as Pickle

# go to SPARC solver directory
os.chdir('/home/maija/maija.fil@gmail.com/THESIS/ASP')


# --------------------------------------------------------------------------------- #
#                                  Helper Functions
# --------------------------------------------------------------------------------- #

def jarwrapper(*args):
    """Starts a sparc solver process, taking in the
     regular sparc input arguments, and returns the
     output of the solver."""
    process = Popen(['java', '-jar', 'sparc.jar'] + list(args), stdout=PIPE, stderr=PIPE)
    ret = []
    while process.poll() is None:
        line = process.stdout.readline()
        if line != '' and line.endswith('\n'):
            ret.append(line[:-1])
    stdout, stderr = process.communicate()
    ret += stdout.split('\n')
    if stderr != '':
        ret += stderr.split('\n')
        # runtime_error = True # uncomment & return to use error msg.
    ret.remove('')
    return ret


def rm_header(result):
    """Removes the header from program output"""
    o = filter(None, result)
    o = [x for x in o if "SPARC" not in x]
    o = [x for x in o if "program translated" not in x]
    return o


# TODO
# create a method to detect and deal with runtime errors

def pick_goal(g):
    """Set must be a list of possible goals in
    the form of a literal"""
    #g = random.choice(ans_set)
    g = list(g)  # convert to list
    g[-2] = 'I'  # insert chosen horizon value
    goal_str = ''.join(g)  # create line to be inserted
    return goal_str


def find_line_id(string, f):
    """Returns line number of a specific string (flag) to be searched for.
    In this case, the flag is a line inserted before the specified goal in
    ASP programs for this project."""
    return [num for [num, line] in enumerate(f) if line.startswith(string)]


def set_goal(inFile, outFile, goal):
    """Adds a line setting the goal to the program
    specified by inFile, and saves it to an output
    file specified by outFile."""

    with open(inFile) as prog:
        lines = prog.readlines()

    # Define Goal flag:
    g_flag = '% Execution Goal'

    line_num = find_line_id(g_flag, lines)

    # Add goal and save program
    lines[line_num[0] + 1] = 'goal(I):-' + goal + '.' + '\n'

    with open(outFile, 'w') as prog:
        prog.writelines(lines)


def out_to_list(sparc_output):
    """Separates the output returned by jarwrapper
    into a list of lists. """
    # check if output is empty
    if len(sparc_output)!=0:
        sparc_output = [i[1:-1] for i in sparc_output]
        sparc_output = [i.split(', ') for i in sparc_output]
    return sparc_output


def run_goal_gen(asp_filename):
    """Finds the answer set of the
    selected goal generation program,
    returns a list of all fluents."""
    args = [asp_filename, '-A']
    # OUTPUT
    result = jarwrapper(*args)
    fluent_set = rm_header(result)
    fluent_set = fluent_set[0]
    # remove braces
    fluent_set = fluent_set[1:-1]
    # add extra paren so it doesn't get removed 
    fluent_set = fluent_set+')'
    # split into a list
    fluent_ls = re.split('\s', fluent_set)
    # remove comma
    fluent_ls = [i[:-1] for i in fluent_ls]
    return fluent_ls


class ExpCondition:
    """A simple object for data collection.
    Keeps the goal literal, execution time,
    plan arity, set of plans, and number
    of plans returned in lists.
    This layout should be improved once it
    is clear what structure is preferrable
    for data analysis, e.g. to  access
    individual entries (trials). """
    def __init__(self):
        self.goal = []
        self.success = []
        self.exe_t = []
        self.arity = []
        self.plans = []
        self.no_plans = []
        self.missing_ax = []    # missing axioms
        self.no_of_missing_ax = []  # number of missing axioms
        self.init_cond = []  # initial conditions


class SecondExp:
    """A simple object for data collection in the second experiment.
    Keeps all categories of ExpCOndition, and adds success, plan
    correctness, and explanations for failed plans. """
    def __init__(self):
        self.goal = []      # goal literal
        self.goalID = []    # simple code for goal literals
        self.plan = []      # plans
        self.success = []   # goal achieved
        self.correct = []   # ground truth success
        self.init_cond = []  # initial conditions
        self.expl = []      # diagnostics output



def find_plan_length(plan_list):
    """Finds plan length indicated by the predicate
    plan_length(i), where i is the first time step
    when the goal holds."""
    if len(plan_list) == 0:
        # no plans were returned
        plan_length = 0
    else:
        # plan length is always the first item in the output
        plan_len_pred = plan_list[0][0]
        # scan it for a number
        re_out = re.search(r"\d+", plan_len_pred)
        # access the match and convert to an integer
        plan_length = int(re_out.group(0))
        if plan_length == 0:
            plan_length = 999
    return plan_length


def get_step(literal):
    """Finds the time step of a given literal.
    It is assumed that time steps are always
    the last item of the literal."""
    # scan input for numbers
    re_out = re.findall(r"\d+", literal)
    # access the match and convert to an integer
    step = int(re_out[-1])
    return step


def get_actors(plan):
    """Returns a list of obj. and agents
    appearing in the plan."""
    words = []
    for i in plan:
        words.extend(re.findall(r"\b[\d\w]{2,}\b", i))
    # remove occurs / plan_length
    actors = []
    actors = [i for i in words if not 'occurs' in i]
    actors = [i for i in actors if not 'plan_length' in i]
    actors = [i for i in actors if not 'goal' in i]
    actors = [i for i in actors if not 'room' in i]
    actors = [i for i in actors if not 'corridor' in i]
    # 3. return list
    return actors


def hist_search(history, occ_plan):
    pln = [i for i in occ_plan if 'occurs' in i]
    steps = len(pln)
    # create a list of all steps
    hist_time = []
    # remove success from hist:
    history = [i for i in history if not 'success' in i]
    for item in history:
        hist_time.append(get_step(item))
    # init empty list of ordered history items
    ordered_hist = []
    # add all items from 0th timestep:
    bool_arr = (np.array(hist_time)==0)
    zeroth = [i for (i, b) in zip(history, bool_arr) if b]
    ordered_hist.extend(zeroth)
    for step in range(1,steps):
        # get relevant actors for that step
        current_steps = pln[step-1:step]
        current_actors = get_actors(current_steps)
        # get history from this step
        bool_arr = np.array(hist_time)==step
        current_hist = [i for (i, b) in zip(history, bool_arr) if b]
        # relevant history:
        for i in current_hist:
            if any(s in i for s in current_actors):
                ordered_hist.append(i)
    return ordered_hist


def add_init_state(program, out_prog, state):
    """"""
    # 1.
    f = open(program, "r")
    contents = f.readlines()
    f.close()
    line_num = find_line_id("%&%& Received initial condition:", contents)
    end_ln = find_line_id("%&%& End of starting state", contents)
    # new initial conditions:
    init_state = [i + '. \n' for i in state]
    # remove lines & add new state
    contents_w = contents[0:line_num[0] + 1]
    contents_w.extend(init_state[0:])
    contents_w.extend(contents[end_ln[0]:-1])
    # write to file
    f = open(out_prog, "w")
    contents_w = "".join(contents_w)
    f.write(contents_w)
    f.close()


def add_plan(plan, in_prog, out_prog):
    # add plan to program:
    f = open(in_prog, "r")
    contents = f.readlines()
    f.close()
    line_num = find_line_id("%&%& Received plan:", contents)
    end_ln = find_line_id("%&%& End of plan", contents)
    # take only occurs
    newpln = [i for i in plan if 'occurs' in i]
    newpln = [i + '. \n' for i in newpln]
    # remove lines inbetween (i.e. old plan) & add new plan
    contents_w = contents[0:line_num[0] + 1]
    contents_w.extend(newpln[0:])
    contents_w.extend(contents[end_ln[0]:-1])
    # write to file
    f = open(out_prog, "w")
    contents_w = "".join(contents_w)
    f.write(contents_w)
    f.close()


def determine_success(asp_output):
    s = 'success'
    if s in asp_output:
        sb = 1
    else:
        sb = 0
    return sb
    
    
def plan_check(formatted_output):
    """Check if plan is pointless, i.e.
    true at t=0. """

#%%
# --------------------------------------------------------------------------------- #
#                       Data recording and program parameters
# --------------------------------------------------------------------------------- #

# instantiate data collection for complete and incomplete domain knowledge conditions
complete_dk = ExpCondition()
partial_dk = ExpCondition()

# set program file names for the 'oracle' (complete domain knowledge) program,
# the 'robot' program which is missing several axioms, thus having incomplete
# domain knowledge, the goal generating program and a program for generating
# random initial conditions.
asp_init = 'init_gen.sp'
asp_goal_set = 'goal-gen-with-constraints.sp'
asp_complete = 'bw-translation-from-al-3.sp'
asp_partial = 'bw-al-3-partial.sp'

#  Generate all possible goals for this domain
goal_ls = run_goal_gen(asp_goal_set)

# Get a random set of initial conditions
init_out = jarwrapper(asp_init, '-A ', '-n', '1')
init_out = rm_header(init_out)
init_list = out_to_list(init_out)
# remove can_support :
init_list = [i for i in init_list[0] if not 'can_support' in i]

# Choose file names for programs with altered goals,
# the source programs are left unchanged.
target_cdk = 'rand-goal-cdk.sp'
target_pdk = 'rand-goal-pdk.sp'


#%% 
# ----------------------------------------------------- #
#                  Experiment 1
# ----------------------------------------------------- #

iters = len(goal_ls)

# save goal list:
with open('goals.tsv', "wb") as tsv_file:
        writer = csv.writer(tsv_file, delimiter='\t')
        writer.writerow(goal_ls)
            
c_all = open('x_1.tsv', 'wb')

#head = ['trial', 'goal', 'init_cond', 'missing_ax', 'miss_ax_n', 'pdk_exe_t', 'cdk_exe_t',
#        'pdk.success', 'cdk.success', 'pdk.arity', 'cdk.arity', 'pdk.plans', 'cdk.plans', 
#        'pdk.n.plans', 'cdk.n.plans']
        
head = ['trial', 'goal','pdk_exe_t', 'cdk_exe_t',
        'pdk.success', 'cdk.success', 'pdk.arity', 'cdk.arity', 'pdk.plans', 'cdk.plans', 
        'pdk.n.plans', 'cdk.n.plans']


writer = csv.writer(c_all, delimiter='\t')
writer.writerow(head)

#%% Create Partial domain knowledge script and set deletion of information:

# No. of axioms to delete:
n_del = 1

# read in complete file:
f = open(asp_complete, 'r')
script = f.readlines()

# get aff-rels. / exec. conds. (through flags)
ec_ln = find_line_id('%&%& E.c.:', script)
ec_end = find_line_id('%% AFFORDANCE AXIOMS END', script)
ar_ln = find_line_id('%&%& A.R.:', script)
ar_end = find_line_id('%&%& A.R. end', script)

exec_conds = script[ec_ln[0]:ec_end[0]]
aff_rels = script[ar_ln[0]:ar_end[0]]
# add newline char!
#exec_conds = [i+'\n' for i in exec_conds]
#aff_rels = [i+'\n' for i in aff_rels]

# connect into 1:
exec_conds_s = "".join(exec_conds)
aff_rels_s = "".join(aff_rels)
# Regex by /d.
ec_ls = re.split('\d\.', exec_conds_s)
aff_rel_ls = re.split('%\s\d\.', aff_rels_s)

# which of these are suitable to delete for this experiment? 
# (complex affordances are what's investigated, regular one's can stay in the script)
ec_complex = [4, 5, 6]
ar_complex = range(3,len(aff_rel_ls)) # aff. rels. involved in the above exec. conds. 

# choose which to keep: sample of total expressions - number to delete
to_del_ec = random.sample(ec_complex, n_del)
to_del_ar = [] # random.sample(ar_complex, n_del)

# write the rest to file (do they still have /n?)
ec_w = [l for i,l in enumerate(ec_ls) if not i in to_del_ec]
ar_w = [l for i,l in enumerate(aff_rel_ls) if not i in to_del_ar]

ec_w = "".join(ec_w)
ar_w = "".join(ar_w)

# pdk = cdk + ec+w + lines inbetween + ar+w + remaining lines
pdk_script = script[0:ec_ln[0]]
pdk_script.extend(ec_w)
pdk_script.extend(script[ec_end[0]:ar_ln[0]])
pdk_script.extend(ar_w)
pdk_script.extend(script[ar_end[0]:])
pdk_script = "".join(pdk_script)
# this is the pdk domain. 

f = open(asp_partial, 'w')
f.write(pdk_script)
f.close()



#%%
for i in range(10):
    # Choose a goal
    goal = pick_goal(goal_ls[i])
    #goal = pick_goal(gls)

    # Write the goal to the target program files.
    set_goal(asp_complete, target_cdk, goal)
    set_goal(asp_partial, target_pdk, goal)
    
    # Set starting conditions:
    init_out = jarwrapper(asp_init, '-A ', '-n', '1')
    init_out = rm_header(init_out)
    init_list = out_to_list(init_out)
    # remove can_support :
    init_list = [i for i in init_list[0] if not 'can_support' in i]
    add_init_state(target_cdk,target_cdk,init_list)
    add_init_state(target_pdk,target_pdk,init_list)

    # Execute program, save output
    t = time.clock()
    cdk_out = jarwrapper(target_cdk, '-A')
    t_end = time.clock()

    t2 = time.clock()
    pdk_out = jarwrapper(target_pdk, '-A')
    t2_end = time.clock()

    cdk_out = rm_header(cdk_out)
    pdk_out = rm_header(pdk_out)

    cdk_plan_ls = out_to_list(cdk_out)
    pdk_plan_ls = out_to_list(pdk_out)

    # find plan length
    cdk_p_len = find_plan_length(cdk_plan_ls)
    pdk_p_len = find_plan_length(pdk_plan_ls)

    complete_dk.goal.append(goal)
    complete_dk.arity.append(cdk_p_len)
    complete_dk.exe_t.append(t_end - t)
    complete_dk.plans.append(cdk_plan_ls)
    complete_dk.no_plans.append(len(cdk_plan_ls))

    partial_dk.goal.append(goal)
    partial_dk.arity.append(pdk_p_len)
    partial_dk.exe_t.append(t2_end - t2)
    partial_dk.plans.append(pdk_plan_ls)
    partial_dk.no_plans.append(len(pdk_plan_ls))
    
    pdkSucc = determine_success(cdk_out)
    cdkSucc = determine_success(pdk_out)
    complete_dk.success.append(cdkSucc)
    partial_dk.success.append(pdkSucc)
    
    if cdk_p_len!=999:
        writer.writerow([i, goal, t2_end, t_end, pdkSucc, cdkSucc,
                         pdk_p_len, cdk_p_len, pdk_plan_ls, cdk_plan_ls,
                         len(pdk_plan_ls), len(cdk_plan_ls)])
    
    

#%% Run when all desired conditions completed: 

c_all.close()

#%%
# save data
with open('results/partial_dk_results_1.pkl', 'wb') as output:
    Pickle.dump(partial_dk, output, Pickle.HIGHEST_PROTOCOL)

with open('results/complete_dk_results_1.pkl', 'wb') as output:
    Pickle.dump(complete_dk, output, Pickle.HIGHEST_PROTOCOL)

#%%
# ----------------------------------------------------- #
#                  Experiment 2
# ----------------------------------------------------- #

# 1. Create experiment object:
experiment_2 = ExpCondition()
diag_frame = SecondExp()
iters = len(goal_ls)

# Choose input files
asp_sim = 'world-sim.sp'
sim = 'sim_test.sp'
asp_diag = 'diag-obs.sp'
diag = 'diag_test.sp'

# Choose number of fluents to show in history with all variables
required_fluents = ["location", "on", "in_hand"]

# Number of axioms deleted:

# Which axioms to delete?

#%%

for i in range(10):
    # Choose a goal
    goal = pick_goal(goal_ls)
    #goal = savedgoal
    # Write the goal to the target  files.
    set_goal(asp_partial, target_pdk, goal)
    # Set starting state:
    # add_init_state(asp_partial, target_pdk, state)
    #add_init_state(asp_sim, sim, state)
    #add_init_state(asp_diag, diag, state)

    # Execute program, save output
    pdk_out = jarwrapper(target_pdk, '-A')
    pdk_out = rm_header(pdk_out)
    pdk_plan_ls = out_to_list(pdk_out)
    # find plan length
    p_len = find_plan_length(pdk_plan_ls)
    # Record to the outer data frame:
    experiment_2.goal.append(goal)
    experiment_2.plans.append(pdk_plan_ls)
    experiment_2.no_plans.append(len(pdk_plan_ls))
    experiment_2.arity.append(p_len)
    #experiment_2.init_cond.append(state)
    #experiment_2.no_of_missing_ax.append()
    #experiment_2.missing_ax.append()
    # 1. was a plan found?
    success = 1 if len(pdk_out) > 0 else 0
    
    # if yes, proceed to loop through plans.
    if success and p_len!=999:
        for j in range(len(pdk_plan_ls)):
            plan_failure = []
            explanations = []
            # get new plan
            plan = pdk_plan_ls[j]
            # add plan to program:
            add_plan(plan, asp_sim, sim)
            # add the starting state from outer loop
            #world_sim = append_program(world_sim, state)
    
            # execute to get feedback as list of fluents
            history_f = run_goal_gen(sim)
            # get relevant history
            test = hist_search(history_f, plan)
    
            # add history and obs to diagnostics program
            f = open(asp_diag, "r")
            contents = f.readlines()
            f.close()
            line_num = find_line_id("%&%& Received history:", contents)
            end_ln = find_line_id("%&%& End of history", contents)
            histln=[]
            #histln = [i[:-1] for i in test]
            histln = [i + '. \n' for i in test]
            # remove old history & add new history and plan
            contents_w = []
            contents_w = contents[0:line_num[0] + 1]
            #contents_w.extend(newln[0:])
            contents_w.extend(histln)
            contents_w.extend(contents[end_ln[0]:-1])
            # write to file
            f = open(diag, "w")
            contents_w = "".join(contents_w)
            f.write(contents_w)
            f.close()
    
            # execute to get feedback
            diag_out = jarwrapper(diag, '-A')
            diag_out = rm_header(diag_out)
            diag_out = out_to_list(diag_out)
    
            # append result arrays:
            #plan_failure.append()
            explanations.append(diag_out)
    
            # Record Results:
            diag_frame.goal.append(goal)
            diag_frame.plan.append(plan)
            diag_frame.success.append(success)
            # 2. Was it correct?
            correct = 1 if 'success' in history_f else 0
            diag_frame.correct.append(correct)
            # 3. What's the explanation for failure?
            diag_frame.expl.append(diag_out)



# is diag obs being written to correctly?


# # save data
# with open('results/partial_dk_results_1.pkl', 'wb') as output:
#     Pickle.dump(partial_dk, output, Pickle.HIGHEST_PROTOCOL)
#
# with open('results/complete_dk_results_1.pkl', 'wb') as output:
#     Pickle.dump(complete_dk, output, Pickle.HIGHEST_PROTOCOL)

# -------------------------------------------- #
#               Data analysis                  #
# -------------------------------------------- #


# load data if necessary
#with open('results/complete_dk_results_1.pkl', 'rb') as input:
#    complete_dk = pickle.load(input)

# make a data frame with non-impossible goals only
# i.e. discard cases where both ans. sets are empty.


# no of goals achieved

# histogram of plan length

# no of plans found for successful goals


# find relevant actors:
# hist_act = []
# # 1. Select all with relevant actors
# for item in history_f:
#     if any(s in item for s in actors):
#         hist_act.append(item)
# # 2. Select only the chosen fluents
# fluents = ["in_hand", "on", "location"]
# final_hist = []
# for item in hist_act:
#     if any(s in item for s in fluents):
#         final_hist.append(item)
# # 3. append all hpd's
# hpds = [i for i in history_f if 'hpd' in i]
# final_hist.extend(hpds)

#%%
from IPython import get_ipython
get_ipython().magic('reset -sf')
