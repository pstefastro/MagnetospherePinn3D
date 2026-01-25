#!/bin/bash
#SBATCH --mail-type=ALL
#SBATCH --mail-user=petros.stefanou@uv.es
#SBATCH --job-name="ff3d"
#SBATCH --workdir=.
#SBATCH --ntasks=1
#SBATCH --time=24:00:00
#SBATCH --partition=astrogpu1
#SBATCH --qos=astrogpu1
#SBATCH --gres=gpu:1
##SBATCH --mem=50G

# Set job id and data directory depending on single or array job
[[ -z "${SLURM_ARRAY_JOB_ID}" ]] && JOB_ID="${SLURM_JOB_ID}" || JOB_ID="${SLURM_ARRAY_JOB_ID}_${SLURM_ARRAY_TASK_ID}"
[[ -z "${SLURM_ARRAY_JOB_ID}" ]] && DATA_DIR="${SLURM_JOB_NAME}_${SLURM_JOB_ID}" || DATA_DIR="${SLURM_JOB_NAME}_${SLURM_ARRAY_JOB_ID}/${SLURM_ARRAY_TASK_ID}"

# Print job id
printf "\n%s\n\n" "==================== Starting job ${JOB_ID} ===================="

# Run the julia script
julia --project=. scripts/RunJob.jl

# Print job information
sacct -X --jobs=${JOB_ID} --format=JobName,JobID,Start,Elapsed,State,ExitCode

printf "\n%s\n\n" "==================== Ending job ${JOB_ID} ===================="

# Move output file to data directory
JOB_DIR=$(cat /tmp/julia_dir_name)
rm /tmp/julia_dir_name  # Clean up
mv -f slurm-${JOB_ID}.out "data/${JOB_DIR}.log"
