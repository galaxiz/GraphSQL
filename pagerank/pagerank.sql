CREATE OR REPLACE FUNCTION rownormalize (E TEXT) RETURNS VOID AS
$$
DECLARE
n INTEGER; --number of nodes
sres INTEGER;
init NUMERIC;
BEGIN
    --Create a row normalized table with all non zero rows to 1/n
    n = numnodes(E);
    DROP TABLE IF EXISTS rownormedge;
    CREATE TABLE IF NOT EXISTS rownormedge (sid INTEGER, did INTEGER, val NUMERIC); 
    EXECUTE 
        'INSERT INTO rownormedge SELECT sid, did, c FROM ' || E ||
        ', (SELECT sid as f, 1/cast(count(*) AS real) AS c FROM '|| E ||
        ' GROUP BY sid) AS T WHERE T.f = '|| E || '.sid';
    
    sres := 0;
    init := 1/n::float;
    --RAISE NOTICE 'init %', init;
    FOR i IN 0..(n-1) LOOP
        SELECT count(*) INTO sres FROM rownormedge WHERE sid = i;
        IF sres = 0 THEN
--            RAISE NOTICE '%',sres;
            FOR j IN 0..(n-1) LOOP
                INSERT INTO rownormedge VALUES (i, j, init);
            END LOOP;
        END IF;
        /*SELECT  count(*) INTO sres FROM rownormedge WHERE sid = i;
        IF sres = 0 THEN
--            RAISE NOTICE '%',sres;
                INSERT INTO rownormedge VALUES (i, i, init);
        END IF;*/
    END LOOP;
    
    FOR j IN 0..(n-1) LOOP
        SELECT count(*) INTO sres FROM rownormedge WHERE did = j;
        IF sres = 0 THEN
            INSERT INTO rownormedge VALUES (j, j, 0);
        END IF;
    END LOOP;
END
$$ LANGUAGE plpgsql;


/*
 * Perform pagerank
 */
CREATE OR REPLACE FUNCTION pagerank (E TEXT) RETURNS VOID AS $$
DECLARE
n INTEGER;
changed INTEGER; -- row changed
init NUMERIC;
iii INTEGER;
BEGIN
    n = numnodes(E);
    RAISE NOTICE 'NUMER OF NODE IS %',n;
    init = 1/n::float;
    DROP TABLE IF EXISTS nn;
    CREATE TEMP TABLE nn (n INTEGER);
    INSERT INTO nn VALUES(n);
    --generate a pagerank vector
    DROP TABLE IF EXISTS pagerank;
    CREATE TABLE pagerank (id INTEGER, val NUMERIC);
    FOR i in 0..(n-1) LOOP
        INSERT INTO pagerank VALUES(i, init);
    END LOOP;

    --insert into pagerank_new select * from pagerank;
    iii := 0;
    LOOP
        iii := iii + 1;
        if iii > 1000 THEN
            exit;
        END IF;
        changed = gimv('rownormedge', 'pagerank', 'pagerank', 'pr_combine2', 'pr_combineall', 'pr_assign', 1);
        RAISE NOTICE '% rows changed!!!!!!!!', changed;
        IF changed = 0 THEN
            EXIT;
        END IF;
    END LOOP;
    DROP TABLE IF EXISTS nn; 
END
$$ LANGUAGE plpgsql;

/*
 * GIM-V operations
 */
 -- combine2
CREATE OR REPLACE FUNCTION pr_combine2(NUMERIC, NUMERIC) RETURNS NUMERIC AS $$
BEGIN
    RETURN 0.85*$1*$2;
END
$$ LANGUAGE plpgsql;

-- assign
CREATE OR REPLACE FUNCTION pr_assign(NUMERIC, NUMERIC) RETURNS NUMERIC AS $$
BEGIN
    RETURN $2;
END
$$ LANGUAGE plpgsql;


-- combineAll
CREATE TYPE pr_type AS(
    sum NUMERIC
);

CREATE OR REPLACE FUNCTION pr_sfunc(t pr_type, NUMERIC) RETURNS pr_type AS 
$$
BEGIN
    t.sum := t.sum+$2;
     -- RAISE NOTICE 'sum is % combine2 %',t.sum,$2;

    RETURN t;
END
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION pr_ffunc(t pr_type) RETURNS NUMERIC AS
$$
DECLARE 
nodenum INTEGER;
res NUMERIC;
BEGIN
    --RAISE NOTICE '%', t.sum+0.15/4::float;
    EXECUTE 'SELECT n FROM nn LIMIT 1' INTO nodenum;
    res := t.sum + 0.15/nodenum::float;
    if nodenum != 6 Then
        --RAISE NOTICE '% %', t.sum, res;
    END if;
    RETURN res;  --the number of nodes
END
$$ LANGUAGE plpgsql;

CREATE AGGREGATE pr_combineall (NUMERIC) (
    SFUNC = pr_sfunc,
    FINALFUNC = pr_ffunc,
    STYPE = pr_type,
    initcond = '(0)'
);
