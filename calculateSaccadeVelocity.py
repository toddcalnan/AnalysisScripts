# -*- coding: utf-8 -*-
"""
Created on Fri Oct 25 12:49:34 2019

@author: tmc54
"""

def calculateSaccadeVelocity(saccadeClusters, sampleRate):
    import numpy as np
    xStart = []
    yStart = []
    xEnd = []
    yEnd = []
    for saccadeIndex in range(0, len(saccadeClusters)):
        xStart.append(saccadeClusters[saccadeIndex][0][1])
        yStart.append(saccadeClusters[saccadeIndex][0][2])
        
        xEnd.append(saccadeClusters[saccadeIndex][-1][1])
        yEnd.append(saccadeClusters[saccadeIndex][-1][2])
        
        xStart = np.asarray(xStart)
        yStart = np.asarray(yStart)
        xEnd = np.asarray(xEnd)
        yEnd = np.asarray(yEnd)
        
        delX = xEnd-xStart
        delY = yEnd-yStart
        
        saccadeSize = len(saccadeClusters[saccadeIndex])*sampleRate
        
        velocity = (delX+delY)/saccadeSize
        return velocity