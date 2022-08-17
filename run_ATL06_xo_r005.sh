#!/bin/bash
#
#-------------------------------------------------------------------
#
usage() {
  echo " "
  echo "Usage: $0 [-h|--help] [-c|--cycle 01 -c|--cycle 02...]"
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
icesheet=Antarctic
rel=005

#
# Check arguments
#
TARGET_DIR=""
cycles=""
while [ $# -gt 0 ] ; do
  case $1 in
    -h|--help) usage; exit 0;;
    -c|--cycle) shift; cycles="${cycles} $1";;
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


# cycles=(01 02 03 04 05 06 07 08 09 10 11 12 13)
# cycles=(14)
work_dir=/ATL06_xo/mjohnson
script_path="/home/mcjohn14/git"

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

cycle_name=""
cycle_dir=${icesheet}/r${rel}/c
for cycle in ${cycles[@]}; do
  cycle_dir+=${cycle}
  cycle_name+=${cycle}
done	
echo ${cycle_dir}
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

done


   # Tile
./make_ATL06_tiles_iceproc_v2.sh $hemisphere $work_dir/${cycle_dir} > out_and_err_files/make_ATL06_tiles_iceproc_${icesheet}_rel${rel}_c${cycle_name}.out 2> out_and_err_files/make_ATL06_tiles_iceproc_${icesheet}_rel${rel}_c${cycle_name}.err
   # Crossovers
./cross_ATL06_tile.sh $hemisphere $work_dir/${cycle_dir}/tiles /ATL06_xo/${cycle_dir} > out_and_err_files/cross_ATL06_tile_${icesheet}_rel${rel}_c${cycle_name}.out 2> out_and_err_files/cross_ATL06_tile_${icesheet}_rel${rel}_c${cycle_name}.err

   # Cleanup
   \rm -rf /work3/mjohnson/${cycle_dir}
   

