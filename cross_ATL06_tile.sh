#!/bin/bash

# Example execution:
# ./cross_ATL06_tile.sh  1 /work2/denis/Arctic/cycle_08/003 /work2/denis/Arctic/cycle_08/xo
# ./cross_ATL06_tile.sh -1 /work2/denis/Antarctic/cycle_08/003 /work2/denis/Antarctic/cycle_08/xo

# ./cross_ATL06_tile.sh -1 /work3/denis/Antarctic/r004/c03/tiles /ATL06_xo/Antarctic/r004/c03 > out_and_err_files/cross_ATL06_tile_Antarctic_r004_c03.out 2> out_and_err_files/cross_ATL06_tile_Antarctic_r004_c03.err

hemisphere=$1   # 1 or -1 for N or S
tiles_dir=$2    # Source directory of ATL06 tiles, must be writable
xo_dir=$3

if [ "$hemisphere" == "-1" ]; then
   mask_file="/home/dfelikso/Data/Quantarctica3/Glaciology/ALBMAP/ALBMAP_Mask.tif"
else
   mask_file="/home/dfelikso/Data/GIMP/GimpIceMask_90m.tif"
fi

script_path="/home/mcjohn14/git"

# Find crossovers
echo "Finding crossovers"
echo " input directory: $tiles_dir"
echo " output directory: $xo_dir"
[ -d $xo_dir ] || mkdir -p $xo_dir

#> xo_queue.txt
#for file in `ls $tiles_dir/E*h5`; do
   #echo python $script_path/pointCollection/scripts/cross_ATL06_tile.py $file $hemisphere $xo_dir >> xo_queue.txt
#   echo python $script_path/pointCollection/scripts/cross_ATL06_tile.py $file $xo_dir --hemisphere $hemisphere --mask_file $mask_file --different_cycles_only --delta_time_max 2592000 >> xo_queue.txt
#   python $script_path/pointCollection/scripts/cross_ATL06_tile.py $file $xo_dir --hemisphere $hemisphere --mask_file $mask_file --different_cycles_only --delta_time_max 2592000 
#done
> xo_queue.txt
for file in `ls $tiles_dir/E*h5`; do
   #echo python $script_path/pointCollection/scripts/cross_ATL06_tile.py $file $hemisphere $xo_dir >> xo_queue.txt
   echo python $script_path/pointCollection/scripts/cross_ATL06_tile.py $file $xo_dir --hemisphere $hemisphere --mask_file $mask_file >> xo_queue.txt
done

parallel -j 36 < xo_queue.txt
#cat xo_queue.txt | parallel --ssh "ssh -q" --workdir . --env PYTHONPATH -S gs615-iceproc1,gs615-iceproc2,gs615-iceproc3,gs615-iceproc4
echo "Crossovers done time `date`"
echo " "

\rm xo_queue.txt

# # Calculate statistics at crossovers
# echo "Calculating crossover statistics"
# python $script_path/IS2_calval/cross_ATL06_statistics.py $xo_dir
# echo "Statistics done time `date`"


