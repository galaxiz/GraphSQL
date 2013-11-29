#! /bin/bash
# Usage plot.h DBName Inputfile Outputfile Pdf K 

start=$(date +%s%N)
psql -d $1 -f 'rd_run.sql' -v DIR=$PWD -v inp=$2 -v K=$5 
end=$(date +%s%N)

echo "set term pdf; set logscale y; set output'$4'; set xlabel 'effect radius'; set ylabel 'count'; plot './effradius.txt' t 'Radius plot for $4' with linespoints" | gnuplot

mkdir -p result
mv effradius.txt result/$3

diff=`echo "scale=3; ($end-$start)/1000000000.1" | bc`;
echo "The Radius Calculation process took $diff seconds"


