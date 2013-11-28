/*
 * Calculate the degree distribution of Graph table E (directed)
 * Out Degree Distribution for a Graph E
 * O THE OUTPUT TABLE
 * i = 1 DIRECTED GRAPH OUT DEGREE DISTRIBUTION
 * i = 2 DIRECTED GRAPH IN DEGREE DISTRIBUTION
 * i = 0 UNDIRECTED GRAPH
 */
CREATE OR REPLACE FUNCTION degreedist (E TEXT, O TEXT, i INTEGER) RETURNS VOID AS $$
BEGIN
    EXECUTE 'DROP TABLE IF EXISTS ' || O;
    EXECUTE 'CREATE TABLE '|| O ||' (deg INTEGER, cnt INTEGER)';
    IF i = 1 THEN -- out degree distribution
        RAISE NOTICE 'Out Degree Distribution';
        EXECUTE 'INSERT INTO '|| O ||' SELECT c, count(*) as cnt
            FROM (SELECT sid, count(*) AS c FROM '
            ||E||' group by sid) as T GROUP BY T.c ORDER BY c DESC';
    ELSIF i = 2 THEN -- in degree distribution
        RAISE NOTICE 'in Degree Distribution';
        EXECUTE 'INSERT INTO '|| O || ' SELECT c, count(*) as cnt
            FROM (SELECT did, count(*) AS c FROM '
            ||E||' group by did) as T GROUP BY T.c ORDER BY c DESC';
    ELSIF i = 0 THEN -- undirected graph 
        RAISE NOTICE 'Undirected: Degree Distribution';
        EXECUTE 'INSERT INTO '|| O || ' SELECT c, count(*) as cnt
           FROM (SELECT did, count(*) AS c FROM '
           ||E||' group by did) as T GROUP BY T.c ORDER BY c DESC';
    END IF;
   
END
$$ LANGUAGE plpgsql;
