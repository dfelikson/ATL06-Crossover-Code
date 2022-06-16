#!/bin/bash

# Example execution:
# ./make_ATL06_tiles_iceproc.sh  1 /work2/denis/Arctic/cycle_08 003 /work2/denis/Arctic/cycle_08/003
# ./make_ATL06_tiles_iceproc.sh -1 /work2/denis/Antarctic/cycle_08 003 /work2/denis/Antarctic/cycle_08/003

# ./make_ATL06_tiles_iceproc.sh -1 /work3/denis/Antarctic 004 03 > out_and_err_files/make_ATL06_tiles_iceproc_A
ntarctic_rel004_c03.out 2> out_and_err_files/make_ATL06_tiles_iceproc_Antarctic_rel004_c03.err
# 
hemisphere=$1   # 1 or -1 for N or S
work_dir=$2
# release=$3      # Not actually used here, so commented
# cycle=$4        # Source directory of ATL06 files, must be writable
script_path="/home/mcjohn14/git"


[ -d $work_dir/index ] || mkdir $work_dir/index

echo "Indexing individual ATL06es for $work_dir"

> file_queue.txt
for file in $work_dir/*ATL06*.h5; do
    this_file_index=$work_dir/index/`basename $file`
    [ -f $this_file_index ] && continue
    echo $file
    #echo "${script_path}/pointCollection/pointCollection/index_glob.py -t ATL06 -H $hemisphere --index_file $t
his_file_index -g $file --dir_root `pwd`/$dir/" >> file_queue.txt
    echo "${script_path}/pointCollection/scripts/index_glob.py -t ATL06 -H $hemisphere --index_file $this_file_
index -g $file"  >> file_queue.txt
done

#pboss.py -s file_queue.txt -j 8 -w -p
parallel -j 40 < file_queue.txt
#cat file_queue.txt | parallel --ssh "ssh -q" --workdir . --env PYTHONPATH -S gs615-iceproc1,gs615-iceproc2,gs6
15-iceproc3,gs615-iceproc4
echo "File indexing done time `date`"

echo "Making a collective ATL06 index for $work_dir"
#index_glob.py --dir_root=`pwd`/$cycle_dir/index/ -t h5_geoindex -H $hemisphere --index_file $cycle_dir/index/G
eoIndex.h5 -g "`pwd`/$cycle_dir/index/*ATL06*.h5" -v --Relative
${script_path}/pointCollection/scripts/index_glob.py --dir_root=`pwd`/$work_dir/index/ -t h5_geoindex -H $hemis
phere --index_file $work_dir/index/GeoIndex.h5 -g "$work_dir/index/*ATL06*.h5" -v --Relative

cycle_tile_dir=$work_dir/tiles
[ -d $cycle_tile_dir ] || mkdir -p $cycle_tile_dir
echo "making a queue of indexing commands for $work_dir"
# make a queue of tiles
${script_path}/pointCollection/scripts/make_tiles.py -H $hemisphere -i $work_dir/index/GeoIndex.h5 -W 100000 -t
 ATL06 -o $cycle_tile_dir -q tile_queue.txt -j ${script_path}/ATL11/ATL06_field_dict.json

# run the queue
echo "running the queue for $work_dir"
parallel -j 40 < tile_queue.txt
#cat tile_queue.txt | parallel --ssh "ssh -q" --workdir . --env PYTHONPATH -S icesat102,icesat103,icesat104,ice
sat105,icesat106,icesat107,icesat108,icesat109,icesat110,icesat111
echo "tile generation done time `date`"

echo "indexing tiles for $work_dir"
cycle_tile_dir=$work_dir/tiles
pushd $cycle_tile_dir
${script_path}/pointCollection/scripts/index_glob.py -H $hemisphere -t indexed_h5 --index_file GeoIndex.h5 -g "
E*.h5" --dir_root `pwd` -v 
popd

#python3 geoindex_test_plot.py $cycle_tile_dir/GeoIndex.h5

\rm file_queue.txt tile_queue.txt
echo "Finished processing for hemisphere $hemisphere and cycle_dir $work_dir/tiles"
echo "Stop time `date`"
