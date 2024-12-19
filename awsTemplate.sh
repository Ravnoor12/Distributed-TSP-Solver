#!/user/bin/bash
weightType=$1
initialguess=$2
randseed=$3
trys=$4

batchjob=$5
name=$6
#path="/users/PWSU0510/w597rxs/workflow"
job_dir="job_aws_$name"
mkdir -p ${job_dir}

cp -f $2 ./$job_dir/
distFile="distance0$weightType.pickle"
cp -f $distFile ./$job_dir/
cp -f tspMod.py ./$job_dir/

cd $job_dir

touch STARTED
output=$(python3 "tspMod.py" $weightType $initialguess $((randseed+32)) $trys)

number=$(echo "$output" | awk -F': ' '{print $2}')
echo $number

mv best_$((randseed+32)).pickle best.pickle

rm STARTED
touch FINISHED

