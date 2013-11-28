echo "set term pdf; set logscale; set logscale y; set output'out1.pdf'; set xlabel 'DEGREE'; set ylabel 'COUNT'; plot './degdist.txt' with linespoints t 'Degree distribution'" | gnuplot;
