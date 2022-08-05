#!/bin/bash
#
#-------------------------------------------------------------------
#
cycles='c0304'
work_dir=/ATL06_xo/Antarctic/r005/$cycles

  # Crossovers
python /home/mcjohn14/git/ICESat-2-utilities/ATL06_xo/find_xover_errors.py $work_dir $cycles > xover_$cycles.out 2> xover_$cycles.err


