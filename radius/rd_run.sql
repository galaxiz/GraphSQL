\set dg :DIR '/radius.sql'
\set t1 :DIR '/basicOperation.sql'
\set t2 :DIR '/utils.sql'
\set inputfile '\'' :DIR '/' :inp '\''
\i :dg
\i :t1
\i :t2

DROP TABLE IF EXISTS rd_edge;
SELECT loaddata_int(:inputfile, 'rd_edge',1);
SELECT compute_radii ('rd_edge', :K);
DROP TABLE IF EXISTS rd_res;
CREATE TABLE rd_res (val INTEGER, count INTEGER);
INSERT INTO rd_res SELECT T.val, T.c FROM (SELECT effradius.val, count(*) as c FROM effradius GROUP BY effradius.val ORDER BY effradius.val) AS T 
WHERE T.c >= 10;
\copy rd_res to effradius.txt with delimiter ' '
