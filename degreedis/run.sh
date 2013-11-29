#! /bin/bash

bash plot.sh air 'data/com-youtube.ungraph.txt' 'res_youtube_ungraph' 'plot/plot_youtube_undirect.pdf' 0 > log/1.txt

bash plot.sh air 'data/soc-pokec-relationships.txt' 'res_soc-pokec_directed_in' 'plot/plot_soc-pockec_directed_out.pdf' 1 > log/2_1.txt

bash plot.sh air 'data/soc-pokec-relationships.txt' 'res_soc-pokec_directed_in' 'plot/plot_soc-pockec_directed_in.pdf' 2 > log/2_2.txt

bash plot.sh air 'data/roadNet-PA.txt' 'res_roadNet-PA_ungraph' 'plot/plot_road_pa_undirect.pdf' 0 > log/3.txt

bash plot.sh air 'data/web-Google.txt' 'res_google_directed_in' 'plot/plot_google_directed_in.pdf' 2 > log/4_1.txt

bash plot.sh air 'data/web-Google.txt' 'res_google_directed_out' 'plot/plot_google_directed_out.pdf' 1 > log/4_2.txt

bash plot.sh air 'data/wiki-Talk.txt' 'res_wikitalk_directed_in' 'plot/plot_wikitalk_directed_in.pdf' 2 > log/5_1.txt

bash plot.sh air 'data/wiki-Talk.txt' 'res_wikitalk_directed_out' 'plot/plot_wikitalk_directed_in.pdf' 1 > log/5_2.txt
