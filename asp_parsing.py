#
# /usr/bin/python2.7
#

import os
import subprocess
from subprocess import Popen, PIPE
from subprocess import *
import re
import random
import time

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
        if line != ('') and line.endswith('\n'):
            ret.append(line[:-1])
    stdout, stderr = process.communicate()
    ret += stdout.split('\n')
    if stderr != '':
        ret += stderr.split('\n')
        runtime_error = True
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

def pick_goal(set):
    """Set must be a list of possible goals in
    the form of a literal"""
    g = random.choice(set)
    g = g[:-1]  # remove comma
    g = list(g)  # convert to list
    g[-2] = 'I'  # insert chosen horizon value
    goal_str = ''.join(g)  # create line to be inserted
    return goal_str


def find_lineID(string, f):
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

    line_num = find_lineID(g_flag, lines)

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
    # Regex the output
    fluent_set = fluent_set[0]
    fluent_ls = re.split('\s', fluent_set)
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
        self.exe_t = []
        self.arity = []
        self.plans = []
        self.no_plans = []


def find_plan_length(plan_list):
    """Finds plan length indicated by the predicate
    plan_length(i), where i is the first time step
    when the goal holds."""
    if len(plan_list) == 0:
        # no plans were returned
        plan_length = []
    else:
        # plan length is always the first item in the output
        plan_len_pred = plan_list[0][0]
        # scan it for a number
        re_out = re.search(r"\d+", plan_len_pred)
        # access the match and convert to an integer
        plan_length = int(re_out.group(0))
    return plan_length


def get_step(literal):
    """Finds the time step of a given literal.
    It is assumed that time steps are always
    the last item of the literal."""
    # plan length is always the first item in the output
    plan_len_pred = plan_list[0][0]
    # scan input for numbers
    re_out = re.findall(r"\d+", literal)
    # access the match and convert to an integer
    step = int(re_out[-1])
    return step


# --------------------------------------------------------------------------------- #
#                       Data recording and program parameters
# --------------------------------------------------------------------------------- #

# instantiate data collection for complete and incomplete domain knowledge conditions
complete_dk = ExpCondition()
partial_dk = ExpCondition()

# set program file names for the 'oracle' (complete domain knowledge) program, and the
# 'robot' program which is missing several axioms, thus having incomplete domain info.
asp_goal_set = 'goal-gen-with-constraints.sp'
asp_complete = 'bw-translation-from-al-3.sp'
asp_partial = 'bw-al-3-partial.sp'

#  Generate all possible goals for this domain
goal_ls = run_goal_gen(asp_goal_set)

# Choose file names for programs with altered goals,
# the source programs are left unchanged.
target_cdk = 'rand-goal-cdk.sp'
target_pdk = 'rand-goal-pdk.sp'


# --------------------------------------------------------------------------------- #
#                                  Plan generation
# --------------------------------------------------------------------------------- #

# Choose a goal
goal = pick_goal(goal_ls)


# Write the goal to the target program files.
set_goal(asp_complete, target_cdk, goal)
set_goal(asp_partial, target_pdk, goal)

# Execute program, save output
t = time.clock()
cdk_out = jarwrapper(target_cdk, '-A')
t_end = time.clock()

t2 = time.clock()
pdk_out = jarwrapper(target_pdk, '-A')
t2_end = time.clock()

cdk_out = rm_header(cdk_out)
pdk_out = rm_header(pdk_out)

# Parse into separate plans
# The particulars of this operation may change
# depending on sparc output and further use of plans.
cdk_plan_ls = out_to_list(cdk_out)
pdk_plan_ls = out_to_list(cdk_out)

# find plan length
cdk_p_len = find_plan_length(cdk_plan_ls)
pdk_p_len = find_plan_length(pdk_plan_ls)

complete_dk.goal.append(goal)
complete_dk.arity.append(cdk_p_len)
complete_dk.exe_t.append(t_end-t)
complete_dk.plans.append(cdk_plan_ls)
complete_dk.no_plans.append(len(cdk_plan_ls))

partial_dk.goal.append(goal)
partial_dk.arity.append(pdk_p_len)
partial_dk.exe_t.append(t2_end - t2)
partial_dk.plans.append(pdk_plan_ls)
partial_dk.no_plans.append(len(pdk_plan_ls))




# -----
# Loop
# -----


