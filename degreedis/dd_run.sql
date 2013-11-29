\set dg :DIR '/degreedistibution.sql'
\set t1 :DIR '/basicOperation.sql'
\set t2 :DIR '/utils.sql'
\set inputfile '\'' :DIR '/' :inp '\''
\i :dg
\i :t1
\i :t2

DROP TABLE IF EXISTS dd_edge;
SELECT loaddata(:inputfile, 'dd_edge',0);
select degreedist('dd_edge','disdis',:mode);
\copy disdis to degdist.txt with delimiter ' '
