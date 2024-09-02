#!/usr/bin/env python3

import glob
import re
from dataclasses import dataclass
from datetime import datetime
import matplotlib.pyplot as plt


@dataclass
class Simulation:
    sim_type: str
    cpu_nb: int
    time_str: str
    time_in_sec: int


def get_sim_and_cpu_nb(filename):
    m = re.match(r"([^/]*)/batch_cpu_nb_(\d*)/.*", filename)
    assert m
    sim = m.group(1)
    cpu_nb = int(m.group(2))
    return sim, cpu_nb


def time_str_to_time_in_sec(time_str):
    pt = datetime.strptime(time_str, "%Mm%S.%fs")
    total_seconds = pt.second + pt.minute * 60 + pt.hour * 3600
    return total_seconds


def get_cpu_nb_and_time_vectors(d: dict[int, Simulation]):
    cpu_nb_vect = sorted(list(d.keys()))
    time_vect = [s.time_in_sec for s in [d[c] for c in cpu_nb_vect]]
    return cpu_nb_vect, time_vect


def plot(d_normal: dict[int, Simulation], d_multi: dict[int, Simulation]):
    fig, ax = plt.subplots()

    x, y = get_cpu_nb_and_time_vectors(d_normal)
    ax.plot(x, y, marker='x', label='normal')
    x, y = get_cpu_nb_and_time_vectors(d_multi)
    ax.plot(x, y, marker='x', label='multi')

    ax.set(
        xlabel="cpu_nb",
        ylabel="time (s)",
        title="Simulation time depending on simulated CPU number",
    )
    ax.grid()
    ax.legend(loc='upper left')
    fig.savefig("sim_speed.png")


d_normal = {}
d_multi = {}
for f in glob.glob("*/batch_*/sim.log"):
    sim_type, cpu_nb = get_sim_and_cpu_nb(f)
    fp = open(f)
    lines = fp.readlines()
    time_str = lines[-3].split()[1]
    time_in_sec = time_str_to_time_in_sec(time_str)
    simulation = Simulation(sim_type, cpu_nb, time_str, time_in_sec)
    if sim_type == "normal":
        d_normal[cpu_nb] = simulation
    else:
        d_multi[cpu_nb] = simulation

for cpu_nb in sorted(d_normal):
    print(d_normal[cpu_nb])
for cpu_nb in sorted(d_multi):
    print(d_multi[cpu_nb])

plot(d_normal, d_multi)
