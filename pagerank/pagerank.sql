/*
 * Rownormalize
 *
 * Author Shiwei Dong
 *
 * Create a row normalized table, each row should have entries and 
 * nonzero rows normalized to 1
 */

CREATE OR REPLACE FUNCTION rownormalize (E TEXT, st Integer) RETURNS VOID AS
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
    IF st = 0 THEN
        EXECUTE 
            'INSERT INTO rownormedge SELECT sid, did, c FROM ' || E ||
            ', (SELECT sid as f, 1/cast(count(*) AS real) AS c FROM '|| E ||
            ' GROUP BY sid) AS T WHERE T.f = '|| E || '.sid';
    ELSE
        EXECUTE 
            'INSERT INTO rownormedge SELECT sid-1, did-1, c FROM ' || E ||
            ', (SELECT sid as f, 1/cast(count(*) AS real) AS c FROM '|| E ||
            ' GROUP BY sid) AS T WHERE T.f = '|| E || '.sid';
    END IF;

    sres := 0;
    init := 1/n::float;

    -- Must make every column have at least 1 entry, else aggregation step will skip those zero columns
    FOR j IN 0..(n-1) LOOP
        --eliminate self loop
        insert into rownormedge select j,j,0 ; 
    END LOOP;
END
$$ LANGUAGE plpgsql;


/*
 * Perform pagerank
 *
 * Author Shiwei Dong
 */
CREATE OR REPLACE FUNCTION pagerank (E TEXT) RETURNS VOID AS $$
DECLARE
n INTEGER;
changed INTEGER; -- row changed
init NUMERIC;
iii INTEGER;
aa float;
norm NUMERIC;
BEGIN
    n = numnodes(E);
    RAISE NOTICE 'NUMER OF NODE IS %',n;
    init = 1/n::float;
    DROP TABLE IF EXISTS nn;
    CREATE TEMP TABLE nn (n INTEGER);
    INSERT INTO nn VALUES(n);
    
    --generate a pagerank vector
    DROP TABLE IF EXISTS pagerank;
    CREATE TABLE pagerank (id INTEGER, val NUMERIC(12,9));
    FOR i in 0..(n-1) LOOP
        INSERT INTO pagerank VALUES(i, init);
    END LOOP;
    
    DROP TABLE IF EXISTS pp;
    CREATE TABLE pp (id INTEGER, val NUMERIC);
    execute testvector(n);
    EXECUTE findzerorows(n);

    -- stopping criteria 20 iterations or norm < 1e-7
    iii := 0;
    LOOP
        iii := iii + 1;
        if iii > 20 THEN
            exit;
        END IF;

        DELETE FROM pp;
        INSERT INTO pp SELECT * FROM pagerank; 
        aa := 0.85*vvmul()/n;
        changed = gimv('rownormedge', 'pagerank', 'pagerank', 'pr_combine2', 'pr_combineall', 'pr_assign', 1);
        RAISE NOTICE '% rows changed!!!!!!!!', changed;
        UPDATE pagerank
            SET val = val + aa;
        IF changed = 0 THEN
            EXIT;
        END IF;
        
        norm := norm();
        RAISE NOTICE 'norm: %', norm;
        IF norm < 0.00000001 THEN
            RAISE NOTICE 'on exit norm: %', norm;
            EXIT;
        END IF;    
    END LOOP;
    DROP TABLE IF EXISTS nn; 
END
$$ LANGUAGE plpgsql;

/*
 *  Calculate the norm of the new pagerank vector and old one
 */
CREATE OR REPLACE FUNCTION norm() RETURNS NUMERIC AS $$
DECLARE 
res NUMERIC;
BEGIN
    SELECT SUM(power(pp.val-pagerank.val,2)) INTO res FROM pp, pagerank WHERE pp.id = pagerank.id;
    RETURN res;
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
    RETURN res;  --the number of nodes
END
$$ LANGUAGE plpgsql;

CREATE AGGREGATE pr_combineall (NUMERIC) (
    SFUNC = pr_sfunc,
    FINALFUNC = pr_ffunc,
    STYPE = pr_type,
    initcond = '(0)'
);

/*
 * Generate a vector with all entries to 1/n
 */
CREATE OR REPLACE FUNCTION testvector(n INTEGER) RETURNS VOID AS $$
DECLARE
init NUMERIC;
BEGIN
    DROP TABLE IF EXISTS vector;
    CREATE TABLE vector (id INTEGER, val NUMERIC);
    init := 1/n::float;
    FOR i IN 0..(n-1) LOOP
        INSERT INTO vector VALUES(i, init);
    END LOOP;
END
$$ LANGUAGE plpgsql;

/*
 * Find zero rows in the pagerank matrix and put it into zr_vetor
 */
CREATE OR REPLACE FUNCTION findzerorows (n INTEGER) RETURNS VOID AS $$
DECLARE
sres INTEGER;
BEGIN
     DROP TABLE IF EXISTS zr_vector;
     CREATE TABLE zr_vector (id INTEGER, val INTEGER);
    -- FOR i IN 0..(n-1) LOOP
        /*SELECT did INTO sres FROM rownormedge WHERE sid = i and val != 0 limit 1;
        if sres is null then
            INSERT INTO zr_vector VALUES(i, 1);
        end if;*//*
        insert into zr_vector select i,1 from (select did from rownormedge where sid = i and val != 0 limit 1 ) as T where T.did is null;
        insert into zr_vector select sid, 1 from (select sid from rownormedge where sid = i and val != 0 limit 1 ) as T where T.did is null;*/
     -- OPTIMIZATION!!!!!
     insert into zr_vector select T.sid,1 from (select sid, count(*) as c from rownormedge group by sid ) as T where t.c = 1;

    --END LOOP;
END
$$ LANGUAGE plpgsql;

/*
 * vector vector multipulication, first vector is row vector second column
 */
CREATE OR REPLACE FUNCTION vvmul () RETURNS NUMERIC AS $$
DECLARE 
res NUMERIC;
BEGIN
    SELECT SUM(zr_vector.val * pagerank.val) INTO res
    FROM zr_vector, pagerank WHERE
        zr_vector.id = pagerank.id;
    return res;
END
$$ LANGUAGE plpgsql;
