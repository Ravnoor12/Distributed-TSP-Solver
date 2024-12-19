#!/usr/bin/bash
# name: Ravnoor Singh
# wNumber: w597rxs
# Project name: Proj03
# Assigned: Oct 29
# Due date: Nov 14
# Tested on: fry
fry='w597rxs@fry.cs.wright.edu'
owens='w597rxs@owens.osc.edu'
aws='ubuntu@3.217.212.133'
awspemfilepath='~w597rxs/aws/sshKeyFor7380.pem' #on fry
wnumber=$(echo "$owens" | awk -F'[@]' '{print $1}')
Pnumber='PWSU0510'
#params needed for the program to run
weightType=$1
initialGuess=$2
randseed=$3
trys=$4
batchjob=$5

#echo "chaning the $2 : $initialGuess"

#cp -f "$2" "initialGuess.pickle"
#cp "initialGuess.pickle" "$initialGuess"

#echo "new value of $2 : $initialGuess"

#cp $2 "initialGuess.pickle"
#cp "initialGuess.pickle" $2

# Assumption: that the proj03.tgz is opened on fry in $HOME
# The above variables (fry,owens,aws) will be edited as needed
# Then submit workflow.sh to slurm
# No other changes will take place

# Data:
# The files distance* will be on fry in /home/w006jwn/proj03data
# and on owens in /users/PWSU0471/nehrbajo/proj03data
# The files database* on owens in /users/PWSU0471/nehrbajo/proj03data
# Assume that the python3.sif will be in your home director on AWS and other standard location


function badInput(){
    echo "bla bla"
    exit 4
}

function getCurrentBest() {
weightType=$1
distFile="database0$weightType.txt"
minDist=$(ssh "$owens" "tail -n 5 /users/PWSU0471/nehrbajo/proj03data/$distFile | head -n 1")
echo "$minDist"
}

function startSetup(){
local fry_dir="/home/$wnumber/workflow"
local prof_dir="/home/w006jwn/proj03data"
local distFile="distance0$weightType.pickle"

if [ ! -f "$fry_dir/$distFile" ]; then
	echo "$distFile not found, copying it"
	cp "$prof_dir/$distFile" "$fry_dir/"

else 
	echo "$distFile exists"

fi
}


function awsSetup(){ 
dir="/home/ubuntu/workflow"
distFile="distance0$weightType.pickle"
ssh -i $awspemfilepath $aws "mkdir -p $dir"
scp -i "$awspemfilepath" "$distFile" "$aws:$dir/"
scp -i "$awspemfilepath" "tspMod.py" "$aws:$dir/"
scp -i "$awspemfilepath" "$initialGuess" "$aws:$dir/"
scp -i "$awspemfilepath" "awsTemplate.sh" "$aws:$dir/"
ssh -i $awspemfilepath $aws "chmod 700 $dir/awsTemplate.sh"
}

function owensSetup(){
dir="/users/$Pnumber/$wnumber/workflow"
distFile="distance0$weightType.pickle"
ssh $owens "mkdir -p $dir"
scp "$initialGuess" "$owens:$dir/"
scp "$distFile" "$owens:$dir/"
scp "tspMod.py" "$owens:$dir/"
scp "owensTemplate.sbatch" "$owens:$dir/"
ssh "$owens" "chmod 700 $dir/owensTemplate.sbatch"
}


function getResults(){
fryfile=$1
owenfile=$2
fry_output_file="/home/$wnumber/workflow/$fryfile"
owens_output_file="/users/$Pnumber/$wnumber/workflow/$owenfile"
#echo "1st $fry_output_file"
#echo "1st $owens_output_file"

fry_distance=$(head -n 1 "$fry_output_file")
owens_distance=$(ssh "$owens" "head -n 1 $owens_output_file")
#min_platform=""
#echo "fry dist :  $fry_distance "
#echo "owen dist : $owens_distance"
if (( $fry_distance < $owens_distance )); then
    min_distance=$fry_distance
    min_platform="FRY"
else
    min_distance=$owens_distance
    min_platform="OWENS"
fi

echo "$min_distance $min_platform"
}


#===========================main code ====================

if [ "$#" -gt 5 ]; then
    echo "checking if inputs are more than 5"
   echo "wrong inputs"
fi


#===========================main program loop ============
START=1
END=$batchjob
if [ -f "savedState.pickle" ]; then
    echo "Saved state found, loading values..."

    readState=$(python3 - <<EOF
import pickle
with open("savedState.pickle", "rb") as f:
    state = pickle.load(f)
    print(state["ITERNATION_STATE"])
    print(state["WEIGHT"])
    print(state["END"])
    print(state["RAND_SEED"])
    print(state["PICKLE_FILE_NAME"])
    print(state["NO_OF_TRYS"])
EOF
    )
    echo "reading the vaalues from saved state : $readState"
    START=$(echo "$readState" | sed -n '1p')
    WEIGHT=$(echo "$readState" | sed -n '2p')
    END=$(echo "$readState" | sed -n '3p')
    RANDSEED=$(echo "$readState" | sed -n '4p')
    PICKLEFILE=$(echo "$readState" | sed -n '5p')
    NOOFTRYS=$(echo "$readState" | sed -n '6p')
    cp "$PICKLEFILE" "$initialGuess"
    weightType=$WEIGHT
    #cp "initialGuess.pickle" "$initialGuess"
    randseed=$RANDSEED
    trys=$NOOFTRYS

    echo "new values $randseed $trys $WEIGHT"
    rm "savedState.pickle"
fi


for (( batch=$START; batch<=$END; batch++ ))
do

echo 'setting up AWS and owens'
echo "start : $START end: $END"
echo "values of variable $weightType $initialGuess $randseed $trys"

#cp $2 "initialGuess.pickle"
#cp "initialGuess.pickle" $2

startSetup
awsSetup

#awsDist=$(ssh -i "$awspemfilepath" "$aws" "cd /home/ubuntu/workflow && bash /home/ubuntu/workflow/awsTemplate.sh $1 $2 $3 $4 $batch")

owensSetup

#randseed=$(($1 + ($batch - 1) * 33))


bestDistance=$(getCurrentBest $weightType)
echo "The Best Distance for distance0$weightType is $bestDistance"


fry_job_id=$(sbatch fryTemplate.sbatch "$weightType" "$initialGuess" "$randseed" "$trys" "$batch" | awk '{print $4}')
owens_job_id=$(ssh "$owens" "(cd /users/$Pnumber/$wnumber/workflow && sbatch owensTemplate.sbatch $weightType $initialGuess $randseed $trys $batch) 2>/dev/null" | awk '{print $4}')

awsDist=$(ssh -i "$awspemfilepath" "$aws" "cd /home/ubuntu/workflow && bash /home/ubuntu/workflow/awsTemplate.sh $weightType $initialGuess $randseed $trys $batch $fry_job_id")

#echo $fry_job_id
#echo $owens_job_id

fry_dir="/home/$wnumber/workflow/job_fry_$fry_job_id"
owens_dir="/users/$Pnumber/$wnumber/workflow/job_owens_$owens_job_id"
aws_dir="/home/ubuntu/workflow/job_aws_$fry_job_id"

echo "above while loop"

while ! test -f "$fry_dir/FINISHED" || test -f "$fry_dir/STARTED"; do
    echo "Waiting for Fry job to complete..."
    sleep 3
done

while ! ssh "$owens" "test -f $owens_dir/FINISHED" || ssh "$owens" "test -f $owens_dir/STARTED"; do
    echo "Waiting for Owens job to complete..."
    sleep 3
done

while ! ssh -i "$awspemfilepath" "$aws" "test -f $aws_dir/FINISHED" || ssh -i "$awspemfilepath" "$aws" "test -f $aws_dir/STARTTED"; do
	echo "Waiting for aws to finish"
	sleep 3
done

result=$(getResults "fry_output" "owen_output")
#echo $result
fry_owen_bestDist=$(echo "$result" | awk '{print $1}')
#fry_owen_bestDist=$(echo "$result" | head -n 1)

#echo $fry_owen_bestDist

if (( $fry_owen_bestDist <= $awsDist )); then
    bestDist=$fry_owen_bestDist
    bestPlat=$(echo "$result" | awk '{print $2}')
elif (( $fry_owen_bestDist > $awsDist )); then
    bestDist=$awsDist
    bestPlat="AWS"
fi

echo "Job $batch : $bestDist $bestPlat"
#echo $bestPlat

if [[ "$bestPlat" == "FRY" ]]; then
	cp "/home/$wnumber/workflow/job_fry_$fry_job_id/best.pickle" "best_$batch.pickle"
	echo "Copied best.pickle from Fry."
elif [[ "$bestPlat" == "OWENS" ]]; then
	scp "$owens:~/workflow/job_owens_$owens_job_id/best.pickle" "best_$batch.pickle"
	echo "copied best.pickle from owen"
elif [[ "$bestPlat" == "AWS" ]]; then
	scp -i $awspemfilepath "$aws:/home/ubuntu/workflow/job_aws_$fry_job_id/best.pickle" "best_$batch.pickle"
	echo "Copied best.pickle from AWS"
fi 

cp "best_$batch.pickle" "$initialGuess"
cp "best_$batch.pickle" "bestIFoundSoFar0$weightType.pickle" 

if [ "$bestDist" -lt "$bestDistance" ]; then
	echo "updating the database"
	data=$(python3 - <<EOF
import pickle
import sys
file_path = "./initialGuess.pickle"
with open(file_path, "rb") as f:
	pickleDist = pickle.load(f)
	picklePath = pickle.load(f)
	print(picklePath)
EOF
	)

	touch "BestestFile$weightType"
	echo "$bestDist" > "BestestFile$weightType"
	echo "$data" >> "BestestFile$weightType"
	scp "./BestestFile$weightType" "$owens:~/"
	ssh $owens "bash ./update03.sh $weightType ~/BestestFile$weightType"	
fi

if [ -f "TERMINATE" ]; then

        echo "TERMINATE signal detected. Saving state and exiting."

	python3 - <<EOF
import pickle

state = {
    "ITERNATION_STATE": $(($batch+1)),
    "WEIGHT": "$weightType",
    "END": $END,
    "RAND_SEED": $randseed,
    "PICKLE_FILE_NAME": "$initialGuess",
    "NO_OF_TRYS": $trys,
}

with open("savedState.pickle", "wb") as f:
    pickle.dump(state, f)
EOF

    echo "State saved to savedState.pickle."
    rm "TERMINATE"
    exit
fi

#initialGuess="best_$batch.pickle"

done

