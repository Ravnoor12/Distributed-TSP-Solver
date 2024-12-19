import sys, getopt
import pickle
import random
import os

def calcDist(thisRoute,distMatrix):
    # from city zero to first index
    distance=distMatrix[0][thisRoute[0]]
    Nm1=len(thisRoute)-1

    # Add distance from one city to the next in the list
    for i in range(Nm1):
        distance+=distMatrix[thisRoute[i]][thisRoute[i+1]]
        
    # Add from last index back to city zero    
    distance+=distMatrix[thisRoute[Nm1]][0]
    return distance

def optimalLocation(route,indx,distMatrix):

    N=len(distMatrix)
    
    # original contribution from Indx
    nextIndx=(indx+1)%N
    #print("index: indx={}  nextIndx={}  N={}".format(indx,nextIndx,N))
    distOriginal=distMatrix[indx-1][indx]+distMatrix[indx][nextIndx]

    # set the best swap to be intialized at no change
    bestIndx=indx
    distMin=10*distOriginal

    for i in range(1,N):
        if not i==indx:
            # original contribution from i
            nextI=(i+1)%N
            distI=distMatrix[i-1][i]+distMatrix[i][nextI]
            # Switch these and recheck distances
            distNewIndx=distMatrix[i-1][indx]+distMatrix[indx][nextI]
            distNewI=distMatrix[indx-1][i]+distMatrix[i][nextIndx]
            distNew=distNewIndx+distNewI
            if distNew<(distOriginal+distI) and distNew<distMin:
                distMin=distNew
                bestIndx=i

    if not bestIndx==indx:
        # We found the best place to swap
        temp=route[indx-1]
        route[indx-1]=route[bestIndx-1]
        route[bestIndx-1]=temp

    return
            
if __name__ == '__main__':

    # no checks for bad inputs
    weight=int(sys.argv[1])
    initialGuess=sys.argv[2]
    randSeed=int(sys.argv[3])
    numOfTrys=int(sys.argv[4])
    
    #read pickle file for distanceMatrix
    distFile="distance0"+sys.argv[1]+".pickle"
    rfile = open(distFile,'rb')
    matrix=pickle.load(rfile)
    rfile.close()

    # N includes zero
    N=len(matrix)
    
    #read initial list_of_cities bestGuess.pickle
    rfile2 = open(initialGuess,'rb')
    best_distIn=pickle.load(rfile2)
    best_route=pickle.load(rfile2)
    rfile2.close()
    
    # Calculate its round trip distance
    # in case the best_distIn was wrong
    best_dist=calcDist(best_route,matrix)

    #print("original: {}".format(best_dist))
    # Need a deep copy
    try_route=best_route.copy()

    # Set random seed once
    random.seed(randSeed)
    
    for i in range(numOfTrys):
        if os.path.isfile("./STOP"):
            break
        # randomly change the route order
        # random.shuffle(try_route)
        r = random.randint(1, N-1)
        optimalLocation(try_route,r,matrix)
        dist_i=calcDist(try_route,matrix)
        if dist_i<best_dist:
            best_dist=dist_i
            best_route=try_route.copy()
            
    # Create a file to save best_route
    myResultName="best_"+sys.argv[3]+".pickle"
    ofile = open(myResultName, 'wb') 
    pickle.dump(int(best_dist),ofile)
    pickle.dump(best_route,ofile)
    ofile.close()
            
    #For Convience print out the tag
    # and is round trip route distance
    print("BEST_{}: {}".format(randSeed,int(best_dist)))
    
