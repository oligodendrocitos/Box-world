#
# /usr/bin/python2.7
#

import os
import subprocess
from subprocess import Popen, PIPE
from subprocess import *
import re
import random

# go to SPARC solver directory
os.chdir('/home/maija/maija.fil@gmail.com/THESIS/ASP')


def jarwrapper(*args):
    """Starts a process """
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
    goal_str = ''.join(goal)  # create line to be inserted
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
    lines[line_num[0] + 1] = goal + '\n'

    with open(outFile, 'w') as prog:
        prog.writelines(lines)


#  LOGIC PROGRAM ARGS
# min_test.sp was the planner used to find min.plans!
args = ['goal-gen-all.sp', '-A']  # Any number of args to be passed to the jar file   '-n 2'
# args = tuple(args)
# OUTPUT
result = jarwrapper(*args)
result = rm_header(result)

# Regex the output
ans_set = result[0]
ls_ans = re.split('\s', ans_set)

# Set desired timestep limits
maxt = range(1, 5)
# choose plan horizon length
horizon_len = maxt[2]
# alternatively, select random plan horizon
# horizon_len = random.choice(maxt)

# Choose a goal
goal = pick_goal(ls_ans)

# insert the new goal
target_prog = 'rand-goal.sp'
set_goal('bw-translation-from-al-3.sp', target_prog, goal)


# Execute program, save output
plan_out = jarwrapper(target_prog, '-A')
plan_out = rm_header(plan_out)

# Parse into separate plans

# Handle large numbers of answer sets

# Save to plan library



