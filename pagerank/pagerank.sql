CREATE OR REPLACE FUNCTION rownormalize (E TEXT) RETURNS VOID AS
$$
DECLARE
n INTEGER; --number of nodes
BEGIN
    --Create a row normalized table with all non zero rows to 1/n
    n = numnodes(E);
    DROP TABLE IF EXISTS rownormedge;
    CREATE TABLE IF NOT EXISTS rownormedge (sid INTEGER, did INTEGER, val NUMERIC); 
    EXECUTE 
        'INSERT INTO rownormedge SELECT sid, did, c FROM ' || E ||
        ', (SELECT sid as f, 1/cast(count(*) AS real) AS c FROM '|| E ||
        ' GROUP BY sid) AS T WHERE T.f = '|| E || '.sid';
END
$$ LANGUAGE plpgsql;
