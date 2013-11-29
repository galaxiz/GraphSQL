CREATE OR REPLACE FUNCTION numNodes(tbname TEXT) RETURNS INTEGER AS $$
DECLARE
res INTEGER;
BEGIN
    EXECUTE format(
        'SELECT COUNT(*) FROM (SELECT distinct sid from %s UNION SELECT distinct did from %s) as U;'
        ,$1,$1) INTO res;

    RAISE NOTICE 'Node count: %', res;
    RETURN res;
END
$$ LANGUAGE plpgsql;
