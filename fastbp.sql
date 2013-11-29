/*
 * Belief propagation
 *
 * Xi Zhao
 */

/*
 * Assumptions assume the basic properties of a matrix
 */
CREATE OR REPLACE FUNCTION compute_bp(adjacencym text,priorv text,hf numeric,
    maximum bigint, error numeric,out_beliefv text)RETURNS VOID AS $body$
DECLARE
    a numeric;
    c numeric;
    i bigint;
BEGIN
    --compute a
    a:=4*$3*$3/(1-4*$3*$3);

    --compute c
    c:=2*$3/(1-4*$3*$3);
    
    --create diagonal matrix
    CREATE TEMP TABLE diagonal(sid integer,did integer,val numeric);

    --create W matrix
    CREATE TEMP TABLE w(sid integer,did integer,val numeric);

    --create tmpprior vector
    CREATE TEMP TABLE tmpprior(id integer, val numeric);

    --copy vector
    EXECUTE format($s$
        INSERT INTO tmpprior
        SELECT * FROM %s
        $s$, $2);

    --compute diagonal matrix
    EXECUTE calc_diagonal($1,'diagonal');

    --compute -aD
    EXECUTE matrixnummul('diagonal',-a);

    --copy A to W
    EXECUTE format($s$
        INSERT INTO w
        SELECT * FROM %s
        $s$, $1);

    --compute cA
    EXECUTE matrixnummul('w',c);

    --compute W=cA-aD
    EXECUTE matrixadd('w','diagonal');
    
    --create output belief vector
    EXECUTE format($s$
        CREATE TABLE %s(id integer, val numeric);
        $s$,$6);

    --copy vector
    EXECUTE format($s$
        INSERT INTO %s
        SELECT * FROM %s
        $s$,$6,$2);

    --loop until converge or maximum iterations
    i:=0
    LOOP
        --compute next Wp
        EXECUTE gimv($1,'tmpprior','tmpprior','combine2_bp','sum','assign_bp',0);

        --add to belief vector
        EXECUTE vectoradd($6,'tmpprior');

        --see changing
        SELECT max(val) INTO c FROM tmpprior;

        --converge or maximum iteration
        --TODO
        i:=i+1;
        IF i>$4 or c<$5 THEN
            EXIT;
        END IF;
    END LOOP;
END
$body$ LANGUAGE plpgsql;

/*
 * calculate diagonal matrix D
 */
CREATE OR REPLACE FUNCTION calc_diagonal(original text,dig text) RETURNS VOID AS $body$
BEGIN
    EXECUTE format($s$
        INSERT INTO %s
        SELECT sid, sid AS did, sum(val) AS val
        FROM %s
        GROUP BY sid;
        $s$, $2,$1);
END
$body$ LANGUAGE plpgsql;

/*
 * combine2 function
 */
CREATE OR REPLACE FUNCTION combine2_bp(numeric,numeric) RETURNS numeric AS $body$
BEGIN
    RETURN $1*$2;
END
$body$ LANGUAGE plpgsql;

/*
 * assign function
 */
CREATE OR REPLACE FUNCTION assign_bp(numeric,numeric) RETURNS numeric AS $body$
BEGIN 
    RETURN $2;
END
$body$ LANGUAGE plpgsql;
