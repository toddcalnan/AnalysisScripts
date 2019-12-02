# -*- coding: utf-8 -*-
"""
Created on Tue Nov 26 12:00:04 2019

@author: tmc54
"""
import os
import numpy as np
from scipy.io import loadmat


path = 'C:/Users/tmc54/Documents/EyeTracking/DukeACT/T2Background'
os.chdir(path)

listOfSubjectFolders = os.listdir('.')
numberOfSubjects = len(listOfSubjectFolders)
for subjectNumber in range(0,1):
    subjectName = listOfSubjectFolders[subjectNumber]
    os.chdir(path)
    os.chdir(subjectName)
    subjectFolderContents = os.listdir('.')
    if subjectFolderContents: 
        fileName = subjectName + '_EGT_Analysis.mat' 
        analysisFile = loadmat(fileName)
        