#!/bin/bash
#
#-------------------------------------------------------------------
#
usage() {
  echo " "
  echo "Usage: $0 [-h|--help] [-i|--icesheet Arctic] [-r|--release 006] [-c|--cycle 01 -c|--cycle 02...] [-x|--xtra 2] [-s|--single]"
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
rel=005
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
    -s|--single) single_cycle=1;;
    --work_dir) work_dir="$1";;
    --script_path) script_path="$1";;
    -*) echo ""; echo 'ERROR: Invalid argument'; usage; exit 3;;
  esac
  shift
done

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

if [ ${single_cycle} == 0 ]; then ##{{{
  for cycle in ${cycles[@]}; do
    cycle_name+=${cycle}
    cycle_dir=${icesheet}/r${rel}/c${cycle_name}

  if [ ${xtra_seg} != 0 ] ; then
    seg_name=_${xtra_seg}_extra_segments  
    cycle_dir+=${seg_name}
  fi      

  if [ ! -d ${work_dir}/${cycle_dir} ]; then
    mkdir -p ${work_dir}/${cycle_dir}
  fi
  done
  
  for cycle in ${cycles[@]}; do
    echo processing cycle $cycle


    echo "Start time `date`"

    for reg in "${regions[@]}"; do

      for file in `ls /cooler/I2-ASAS/rel${rel}/ATL06/ATL06_*_????${cycle}${reg}_${rel}_*.h5`; do
        newfile=`echo $file | rev | cut -d'/' -f1 | rev`
        ln -s $file ${work_dir}/${cycle_dir}/$newfile
      done

    done
      echo "Copy done time `date`"

  done

  # Look for multiple versions of the same file
  for file_v01 in `ls ${work_dir}/${cycle_dir}/*01.h5`; do
   
     file_template=`echo $file_v01 | rev | cut -d'/' -f1 | rev | cut -d'_' -f1-4`
     n_files_all_versions=`ls -l ${work_dir}/${cycle_dir}/$file_template*h5 | wc -l`
     if [ $n_files_all_versions -gt 1 ]; then
        file_highest_version=`ls -ltr /cooler/I2-ASAS/rel${rel}/ATL06/$file_template*h5 | tail -1 | awk '{print $9}'`
        filename_highest_version=`echo $file_highest_version | rev | cut -d'/' -f1 | rev`
        rm -rf ${work_dir}/${cycle_dir}/$file_template*h5
        ln -s $file_highest_version ${work_dir}/${cycle_dir}/$filename_highest_version
     fi
   
   done

  # Tile
  ./make_ATL06_tiles_iceproc_v2.sh $hemisphere $work_dir/${cycle_dir} > out_and_err_files/make_ATL06_tiles_iceproc_${icesheet}_rel${rel}_c${cycle_name}_${seg_name}.out 2> out_and_err_files/make_ATL06_tiles_iceproc_${icesheet}_rel${rel}_c${cycle_name}_${seg_name}.err
  # Crossovers
  ./cross_ATL06_tile.sh $hemisphere $work_dir/${cycle_dir}/tiles /ATL06_xo/${cycle_dir} ${xtra_seg} > out_and_err_files/cross_ATL06_tile_${icesheet}_rel${rel}_c${cycle_name}_${seg_name}.out 2> out_and_err_files/cross_ATL06_tile_${icesheet}_rel${rel}_c${cycle_name}_${seg_name}.err

  # Cleanup
  \rm -rf /ATL06_xo/mjohnson/${cycle_dir}
##}}}
else ##{{{
  for cycle in ${cycles[@]}; do
    cycle_name+=${cycle}
  done

  cycle_dir=${icesheet}/r${rel}/c${cycle_name}

  if [ ${xtra_seg} != 0 ] ; then
    seg_name=_${xtra_seg}_extra_segments  
    cycle_dir+=${seg_name}
  fi      

  if [ ! -d ${work_dir}/${cycle_dir} ]; then
    mkdir -p ${work_dir}/${cycle_dir}
  fi	
 
  for cycle in ${cycles[@]}; do
    echo processing cycle $cycle


    echo "Start time `date`"

    for reg in "${regions[@]}"; do

      for file in `ls /cooler/I2-ASAS/rel${rel}/ATL06/ATL06_*_????${cycle}${reg}_${rel}_*.h5`; do
        newfile=`echo $file | rev | cut -d'/' -f1 | rev`
        ln -s $file ${work_dir}/${cycle_dir}/$newfile
      done

    done
      echo "Copy done time `date`"
  
   # Look for multiple versions of the same file
   for file_v01 in `ls ${work_dir}/${cycle_dir}/*01.h5`; do
   
      file_template=`echo $file_v01 | rev | cut -d'/' -f1 | rev | cut -d'_' -f1-4`
      n_files_all_versions=`ls -l ${work_dir}/${cycle_dir}/$file_template*h5 | wc -l`
      if [ $n_files_all_versions -gt 1 ]; then
         file_highest_version=`ls -ltr /cooler/I2-ASAS/rel${rel}/ATL06/$file_template*h5 | tail -1 | awk '{print $9}'`
         filename_highest_version=`echo $file_highest_version | rev | cut -d'/' -f1 | rev`
         rm -rf ${work_dir}/${cycle_dir}/$file_template*h5
         ln -s $file_highest_version ${work_dir}/${cycle_dir}/$filename_highest_version
      fi
    
   done

     # Tile
    ./make_ATL06_tiles_iceproc_v2.sh $hemisphere $work_dir/${cycle_dir} > out_and_err_files/make_ATL06_tiles_iceproc_${icesheet}_rel${rel}_c${cycle_name}_${seg_name}.out 2> out_and_err_files/make_ATL06_tiles_iceproc_${icesheet}_rel${rel}_c${cycle_name}_${seg_name}.err
     # Crossovers
    ./cross_ATL06_tile.sh $hemisphere $work_dir/${cycle_dir}/tiles /ATL06_xo/${cycle_dir} ${xtra_seg} > out_and_err_files/cross_ATL06_tile_${icesheet}_rel${rel}_c${cycle_name}_${seg_name}.out 2> out_and_err_files/cross_ATL06_tile_${icesheet}_rel${rel}_c${cycle_name}_${seg_name}.err

     # Cleanup
     \rm -rf /ATL06_xo/mjohnson/${cycle_dir}
  done   
fi
##}}}
