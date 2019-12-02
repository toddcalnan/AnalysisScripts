# -*- coding: utf-8 -*-
"""
Created on Mon Oct 21 15:08:19 2019

@author: tmc54
"""

import pandas as pd
import os
import numpy as np

path = "C:/Users/tmc54/Desktop/ACE_EGT_Segmented" # where the subject data is located
os.chdir(path) # change the path to where the subject data is located

excelData = pd.read_excel('ACE710008_segmented.xls') # read the Excel file
gazeEventTypeData = excelData.loc[:,'GazeEventType']
originalData = excelData.loc[:, ['SegmentName','GazePointX (MCSpx)','GazePointY (MCSpx)']] # pulling out just the data that we actually need from the Excel data

saccadeRows = gazeEventTypeData.str.find('Saccade') # find which samples are saccades

saccadeData = originalData[saccadeRows == 0] # pull out only the data for saccade samples

## Find start and end points of each saccade cluster

saccadeIndexSeries = pd.Series(saccadeData.index) # create a series object from the index of the saccadeData
saccadeIndexJumps = saccadeIndexSeries-saccadeIndexSeries.shift() > 1 # find where there are jumps between saccade indices
saccadeEndPoints = saccadeIndexJumps[saccadeIndexJumps].index # boolean indexing
saccadeStartPoints = saccadeEndPoints + 1 # starting index is just going to be right after the end index
saccadeStartPoints = saccadeStartPoints.values # convert to numpy array for ease of use
saccadeEndPoints = saccadeEndPoints.values # convert to numpy array for ease of use 
saccadeStartPoints = np.insert(saccadeStartPoints,0,0) # we start at 0
saccadeEndPoints = np.append(saccadeEndPoints, saccadeIndexSeries.size) # we end at the end of the saccade samples

## Smooth this section out using list comprehension
saccadeRange = []
numberOfSaccades = saccadeStartPoints.size
for index in range(0,numberOfSaccades):
    # need to mess with inclusivity
    saccadeRange.append(range(saccadeStartPoints[index],saccadeEndPoints[index])) # find the range of samples for each individual saccade
 
saccadeData = saccadeData.values # convert from dataframe to matrix

individualSaccadeClusters = []
for index in range(0,numberOfSaccades):
    if len(saccadeRange[index]) != 0: # removing saccades that only last one sample
        individualSaccadeClusters.append(saccadeData[saccadeRange[index]]) # pull out data for the individual saccade
    
      
## Now that we have saccade clusters, see what segment they each start and stop in
segmentStart = []
segmentEnd = []
db = []
sandwich = []
ja = []
mt = []
mismatch = []
conditionNumbersDB = [1,3,5,7,9,11,13,15,17,19,21]
conditionNumbersJA = [4,6,8,10]
conditionNumbersSandwich = [2,12]
conditionNumbersMT = [14,16,18,20]
for index in range(0,len(individualSaccadeClusters)):
    segmentStart.append(individualSaccadeClusters[index][0][0]) # what segment the saccade starts in
    segmentEnd.append(individualSaccadeClusters[index][-1][0]) # what segment the saccade ends in 
    if segmentStart[index] == segmentEnd[index]:
        if segmentStart[index] in conditionNumbersDB:
            db.append(individualSaccadeClusters[index])
        elif segmentStart[index] in conditionNumbersSandwich:
            sandwich.append(individualSaccadeClusters[index])
        elif segmentStart[index] in conditionNumbersJA:
            ja.append(individualSaccadeClusters[index])
        elif segmentStart[index] in conditionNumbersMT:
            mt.append(individualSaccadeClusters[index])
    else: 
        mismatch.append(individualSaccadeClusters[index])        

## need to take out saccades that are made purely of nans
firstSegmentSaccade = []
secondSegmentSaccade = []        
## deal with mismatches
for mismatchIndex in range(0,len(mismatch)):
    saccadeSplitLocation = np.where(np.diff(mismatch[mismatchIndex].T[0]))
    saccadeSplitLocation = int(saccadeSplitLocation[0])+1
    firstSegmentSaccade.append(mismatch[mismatchIndex][:saccadeSplitLocation])
    secondSegmentSaccade.append(mismatch[mismatchIndex][saccadeSplitLocation:]) 

## move split saccades to their appropriate conditions
    if len(firstSegmentSaccade[mismatchIndex]) > 1: # need to make sure that the split saccades still have more than one sample
        if firstSegmentSaccade[mismatchIndex][0][0] in conditionNumbersDB:
            db.append(firstSegmentSaccade[mismatchIndex])
        elif firstSegmentSaccade[mismatchIndex][0][0] in conditionNumbersSandwich:
            sandwich.append(firstSegmentSaccade[mismatchIndex])
        elif firstSegmentSaccade[mismatchIndex][0][0] in conditionNumbersJA:
            ja.append(firstSegmentSaccade[mismatchIndex])
        elif firstSegmentSaccade[mismatchIndex][0][0] in conditionNumbersMT:
            mt.append(firstSegmentSaccade[mismatchIndex])
            
    if len(secondSegmentSaccade[mismatchIndex]) > 1:
        if secondSegmentSaccade[mismatchIndex][0][0] in conditionNumbersDB:
            db.append(secondSegmentSaccade[mismatchIndex])
        elif secondSegmentSaccade[mismatchIndex][0][0] in conditionNumbersSandwich:
            sandwich.append(secondSegmentSaccade[mismatchIndex])
        elif secondSegmentSaccade[mismatchIndex][0][0] in conditionNumbersJA:
            ja.append(secondSegmentSaccade[mismatchIndex])
        elif secondSegmentSaccade[mismatchIndex][0][0] in conditionNumbersMT:
            mt.append(secondSegmentSaccade[mismatchIndex]) 

## Calculate velocity for each condition

