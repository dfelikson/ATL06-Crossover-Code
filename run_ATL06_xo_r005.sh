#!/bin/bash
#
#-------------------------------------------------------------------
#
usage() {
  echo " "
  echo "Usage: $0 [-h|--help] [-i|--icesheet Arctic] [-r|--release 006] [-c|--cycle 01 -c|--cycle 02...] [-x|--xtra 2]"
  cat << EOF_USAGE

TBD

  - If executing with NOHUP, use the --force option

  - If the optional -f (force) argument is supplied, the user is not prompted
    for confirmation to continue.

EOF_USAGE
}
#
#-------------------------------------------------------------------
#
icesheet=Arctic
release=005
single_cycle=0
cycle_name=""
work_dir=/ATL06_xo/mjohnson
script_path="/home/mcjohn14/git"
#
# Check arguments
#
TARGET_DIR=""
cycles=""
while [ $# -gt 0 ] ; do
   case $1 in
      -h|--help) usage; exit 0;;
      -i|--icesheet) shift; icesheet="$1";;
      -r|--release) shift; release="$1";;
      -c|--cycle) shift; cycles="${cycles} $1";;
      -x|--xtra) shift; xtra_seg="$1";;
      --work_dir) shift; work_dir="$1";;
      --script_path) shift; script_path="$1";;
      --test_run) test_run=1;;
      -*) echo ""; echo 'ERROR: Invalid argument'; usage; exit 3;;
   esac
   shift
done

#if [ `whoami` != "atl06_xo" ]; then
#   echo ERROR: This script must be run using the atl06_xo service account! Exiting.
#   exit
#fi

#
# Determine cycles to be used
#
if [ "${cycles}" == "" ] ; then
   cycles=(14)
fi
if [ "${xtra_seg}" == "" ] ; then
   xtra_seg=0
   seg_name=""
fi


if [ "$icesheet" == "Arctic" ]; then
   hemisphere=1
   regions=( 03 04 05 )
elif [ "$icesheet" == "Antarctic" ]; then
   hemisphere=-1
   regions=( 10 11 12 )
else
   echo Invalid icesheet!
   exit
fi

for cycle in ${cycles[@]}; do
   cycle_name+=${cycle}
done

cycle_dir=${icesheet}/r${release}/c${cycle_name}

if [ ${xtra_seg} != 0 ] ; then
   seg_name=_${xtra_seg}_extra_segments  
   cycle_dir+=${seg_name}
fi      

if [ ! -d ${work_dir}/${cycle_dir} ]; then
   mkdir -p ${work_dir}/${cycle_dir}
fi	

if [ ! -d /ATL06_xo/${cycle_dir} ]; then
   mkdir -p /ATL06_xo/${cycle_dir}
fi	

# Echo the setup into a file in /ATL06_xo/$cycle_dir ##{{{
exec > /ATL06_xo/$cycle_dir/run_ATL06_xo_r005.out
echo -- Setup --
echo icesheet: $icesheet
echo release: $release
echo cycles: $cycles
echo xtra_seg: $xtra_seg
echo single_cycle: $single_cycle
echo work_dir: $work_dir
echo script_path: $script_path
echo test_run: $test_run
echo -- Setup --
echo

if [ "$test_run" != "1" ]; then
  echo -- Git repository checks --
  basedir=$(dirname $0)
  basedir_git_log=$(cd $basedir && git log -1 | head -n 1)
  if [[ "$basedir_git_log" != *"commit"* ]]; then
    echo The directory $basedir is not a git repository! Cannot log commit hash. Exiting! >&2
    exit
  fi
  basedir_git_status=$(cd $basedir && git status --porcelain)
  if [[ ! -z "$basedir_git_status" ]]; then
     echo The code in the ATL06-Crossover-Code repository "(directory: $basedir)" has the following uncommitted changes. Exiting! >&2
     echo "$basedir_git_status" >&2
     exit
  fi
  pointCollectiondir=${script_path}/pointCollection
  pointCollection_git_log=$(cd $pointCollectiondir && git log -1 | head -n 1)
  if [[ "$pointCollection_git_log" != *"commit"* ]]; then
    echo The directory $pointCollectiondir is not a git repository! Cannot log commit hash. Exiting! >&2
    exit
  fi
  pointCollectiondir_git_status=$(cd $pointCollectiondir && git status --porcelain)
  if [[ ! -z "$pointCollectiondir_git_status" ]]; then
     echo The code in the pointCollection repository "(directory: $pointCollectiondir)" has the following uncommitted changes. Exiting! >&2
     echo "$pointCollectiondir_git_status" >&2
     exit
  fi

  echo This processing uses the following code versions:
  echo " " ATL06-Crossover-Code: $basedir_git_log
  echo " " pointCollection: $pointCollection_git_log
  echo -- Git repository checks --
  echo
fi
##}}}

echo "[`date`] Starting run script"

for cycle in ${cycles[@]}; do
   echo " Linking ATL06 files for cycle $cycle"
   for reg in "${regions[@]}"; do
      for file in `ls /cooler/I2-ASAS/rel${release}/ATL06/ATL06_*_????${cycle}${reg}_${release}_*.h5`; do
         newfile=`echo $file | rev | cut -d'/' -f1 | rev`
         ln -s $file ${work_dir}/${cycle_dir}/$newfile
      done
   done
done
echo "[`date`] Linking finished"

# Look for multiple versions of the same file
for file_v01 in `ls ${work_dir}/${cycle_dir}/*01.h5`; do
   file_template=`echo $file_v01 | rev | cut -d'/' -f1 | rev | cut -d'_' -f1-4`
   n_files_all_versions=`ls -l ${work_dir}/${cycle_dir}/$file_template*h5 | wc -l`
   if [ $n_files_all_versions -gt 1 ]; then
      file_highest_version=`ls -ltr /cooler/I2-ASAS/rel${release}/ATL06/$file_template*h5 | tail -1 | awk '{print $9}'`
      filename_highest_version=`echo $file_highest_version | rev | cut -d'/' -f1 | rev`
      rm -rf ${work_dir}/${cycle_dir}/$file_template*h5
      ln -s $file_highest_version ${work_dir}/${cycle_dir}/$filename_highest_version
   fi
done

# Tile
echo "[`date`] Making tiles"
./make_ATL06_tiles_iceproc.sh $hemisphere $work_dir/${cycle_dir} $script_path > out_and_err_files/make_ATL06_tiles_iceproc_${icesheet}_rel${release}_c${cycle_name}${seg_name}.out 2> out_and_err_files/make_ATL06_tiles_iceproc_${icesheet}_rel${release}_c${cycle_name}${seg_name}.err
#echo make_ATL06_tiles_iceproc.sh $hemisphere $work_dir/${cycle_dir} $script_path

# Crossovers
echo "[`date`] Finding crossovers"
./cross_ATL06_tile.sh $hemisphere $work_dir/${cycle_dir}/tiles /ATL06_xo/${cycle_dir} ${xtra_seg} $script_path > out_and_err_files/cross_ATL06_tile_${icesheet}_rel${release}_c${cycle_name}${seg_name}.out 2> out_and_err_files/cross_ATL06_tile_${icesheet}_rel${release}_c${cycle_name}${seg_name}.err
#echo cross_ATL06_tile.sh $hemisphere $work_dir/${cycle_dir}/tiles /ATL06_xo/${cycle_dir} ${xtra_seg} $script_path

# Cleanup
\rm -rf ${work_dir}/${cycle_dir}

echo "[`date`] Run script complete"

