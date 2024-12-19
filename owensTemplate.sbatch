#!/bin/bash
#SBATCH --job-name=proj03_fry_JOB_ID
#SBATCH --output=owen_output
#SBATCH --account=PWSU0510
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --time=00:50:00

weightType=$1
initialguess=$2
randseed=$3
trys=$4
batchjob=$5
#path="/users/PWSU0510/w597rxs/workflow"
job_dir="job_owens_${SLURM_JOB_ID}"
mkdir -p ${job_dir}

cp -f $2 ./$job_dir/
distFile="distance0$weightType.pickle"
cp -f $distFile ./$job_dir/
cp -f tspMod.py ./$job_dir/

cd ${job_dir}
touch STARTED
min_dist=999999999
best_process_dir=""

for i in {16..31}; do
	rand_seed=$((randseed + i))
	process_dir="process_${rand_seed}"
	mkdir -p ${process_dir}
	cd ${process_dir}
	ln -sf ../$2 ./initialGuess.pickle
	ln -sf ../$distFile ./$distFile
	ln -sf ../tspMod.py ./tspMod.py
	output=$(singularity --silent exec ~nehrbajo/python3.sif python3 "tspMod.py" "$1" "$2" "$rand_seed" "$4")
	number=$(echo "$output" | awk -F': ' '{print $2}')
	if [[ "$number" -lt "$min_dist" ]]; then
		min_dist=$number
		best_process_dir=$process_dir
		rand_val=$rand_seed
	fi
	cd ..

done

echo "$min_dist"
echo "$best_process_dir"

if [[ -n "$best_process_dir" ]]; then
    cp -f "$best_process_dir/best_${rand_val}.pickle" "best.pickle"
fi

rm STARTED
touch FINISHED

