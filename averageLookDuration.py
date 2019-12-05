# -*- coding: utf-8 -*-
"""
Created on Tue Nov 26 12:00:04 2019

@author: tmc54
"""
import os
from scipy.io import loadmat
import numpy as np

path = 'C:/Users/tmc54/Documents/EyeTracking/DukeACT/T2Background'
os.chdir(path)

listOfSubjectFolders = os.listdir('.')
numberOfSubjects = len(listOfSubjectFolders)
for subjectNumber in range(0,1): 
    subjectName = listOfSubjectFolders[subjectNumber] # get subject name
    os.chdir(path) # cd into the path
    os.chdir(subjectName) # cd into the subject's folder
    subjectFolderContents = os.listdir('.') # list the contents of the subject's folder
    if subjectFolderContents: # if there are files in the subject's folder
        fileName = subjectName + '_EGT_Analysis.mat' # name of the mat file for the subject
        analysisFile = loadmat(fileName) # load the subject's mat file
        datFileName = 'dat_' + subjectName # the name of the dat struct where the important data is saved
        data = analysisFile[datFileName] # look at just the 'dat_*' struct in the mat file
        segmentNames = data.dtype.names # list of segment names for this subject, 21 segments expected
        gazeOnMedia = {n: data[n][0,0]['gazeonmedia'][0,0] for n in segmentNames} # go through the dat file, pull out data for each segment, make a dictionary
        chronologicalSegmentOrder = ['DB1', 'sandwich1', 'DB2', 'JAmoose', 'DB3', 'JArooster', 'DB4', 'JAmonkey', 'DB5', 'JApenguin', 'DB6', 'sandwich2', 'DB7', 'MTmonkey', 'DB8', 'MTpenguin', 'DB9', 'MTrooster', 'DB10', 'MTmoose', 'DB11'];
        socialSegmentOrder = ['DB1', 'DB2', 'DB3', 'DB4', 'DB5', 'DB6', 'DB7', 'DB8', 'DB9', 'DB10', 'DB11']
        chronologicalGazeOnMedia = [gazeOnMedia[m] for m in chronologicalSegmentOrder]
        nanLocations = [];
        for m in range(0,len(chronologicalGazeOnMedia)):
            nanLocations = np.argwhere(np.isnan(chronologicalGazeOnMedia[m])) #need to make nanLocations a list of lists as well