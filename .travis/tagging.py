

import os

mydir="/home/max/repos/MISP-dockerized-robot/.travis/../"

base_dir = mydir

from os import listdir

dirs = listdir(base_dir)

versions = dict()


for folder in dirs:
    major = int(folder.split(".")[0])
    minor = int(folder.split(".")[1].split("-")[0])

    if (not versions.get(major) or (versions.get(major)[0] < minor)):
        versions[major] = [minor, folder]  

print versions