#!/bin/bash
#SBATCH --job-name=proj03_$JOB_ID
#SBATCH --output=fry_output
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --time=00:50:00

weightType=$1
initialguess=$2
randseed=$3
trys=$4

batchjob=$5

job_dir="job_fry_${SLURM_JOB_ID}"
mkdir -p ${job_dir}

cp -f $2 ./$job_dir/
distFile="distance0$weightType.pickle"
cp -f $distFile ./$job_dir/
cp -f tspMod.py ./$job_dir/
cd ./${job_dir}

#echo "running before started"
touch STARTED

min_number=9999999999
best_process_dir=""
seed=$3
for i in {1..15}; do
    #echo "running loop first line"
    rand_seed=$((randseed+i))
    process_dir="process_${rand_seed}"
    mkdir -p ${process_dir}
    
    cd ${process_dir}
    
    ln -sf ../$2 ./initialGuess.pickle
    ln -sf ../$distFile ./$distFile
    ln -sf ../tspMod.py ./tspMod.py

    # Run tspMod.py and capture the output
    output=$(python3 "tspMod.py" "$1" "$2" "$rand_seed" "$4")
    number=$(echo "$output" | awk -F': ' '{print $2}')
    
    # Check if this number is the new minimum
    if [[ "$number" -lt "$min_number" ]]; then
        min_number=$number
	seed=$rand_seed
        best_process_dir=$process_dir  # Update best process directory
    fi
    cd ..
done

echo "$min_number"
echo "$best_process_dir"

# Copy the best .pickle file to the workflow directory if a minimum was found
if [[ -n "$best_process_dir" ]]; then
    cp -f "$best_process_dir/best_${seed}.pickle" "./best.pickle"
fi

rm STARTED
touch FINISHED

