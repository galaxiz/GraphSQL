\set t :DIR '/pagerank.sql'
\set t1 :DIR '/basicOperation.sql'
\set t2 :DIR '/utils.sql'
\set inputfile '\'' :DIR '/' :inp '\''
\i :t
\i :t1
\i :t2

DROP TABLE IF EXISTS edge;
SELECT loaddata_int(:inputfile, 'edge', 1);
SELECT rownormalize('edge', :ifs);
SELECT pagerank('edge');
DROP TABLE IF EXISTS pp_res;
CREATE TABLE pp_res (val NUMERIC, count INTEGER);
INSERT INTO pp_res SELECT pagerank.val, count(*) FROM
    pagerank GROUP BY pagerank.val;
\COPY pp_res TO 'pr.txt' DELIMITER ' '
