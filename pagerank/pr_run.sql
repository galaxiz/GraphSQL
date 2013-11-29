DROP TABLE IF EXISTS pp_res;
CREATE TABLE pp_res (val NUMERIC, count INTEGER);
INSERT INTO pp_res SELECT pagerank.val, count(*) FROM
    pagerank GROUP BY pagerank.val;
\COPY pp_res TO 'pr.txt' DELIMITER ' '
