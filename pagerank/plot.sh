echo "set term pdf; set logscale; set logscale y; set output'pr.pdf'; set     xlabel 'pagerank'; set ylabel 'COUNT'; plot './pr.txt' t 'Pagerank'" | gnuplot;  

