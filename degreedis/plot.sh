#! /bin/bash
# Usage plot.h DBName Inputfile Outputfile Pdf Mode

start=$(date +%s%N)
psql -d $1 -f 'dd_run.sql' -v DIR=$PWD -v inp=$2 -v mode=$5
end=$(date +%s%N)

echo "set term pdf; set logscale; set logscale y; set output'$4'; set     xlabel 'degree'; set ylabel 'COUNT'; plot './degdist.txt' t 'Degree Distibution for $4'" | gnuplot

mkdir -p result
mv degdist.txt result/$3

diff=`echo "scale=3; ($end-$start)/1000000000.1" | bc`;
echo "The Degree Distribution process took $diff seconds"


