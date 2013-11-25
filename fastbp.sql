/*
 * Belief propagation
 *
 * Xi Zhao
 */
CREATE OR REPLACE FUNCTION compute_bp(adjacencym text,priorv text,hf numeric,out_beliefv text)RETURNS VOID AS $body$
DECLARE
    a numeric;
    c numeric;
BEGIN
    --compute a
    a:=4*$3*$3/(1-4*$3*$3);

    --compute c
    c:=2*$3/(1-4*$3*$3);
    
    --create diagonal matrix
    CREATE TEMP TABLE diagonal(sid integer,did integer,val numeric);

    --create W matrix
    CREATE TEMP TABLE w(sid integer,did integer,val numeric);

    --compute diagonal matrix
    EXECUTE calc_diagonal($1,'diagonal');

    --compute -aD
    EXECUTE matrixnummul('diagonal',-a);

    --copy A to W
    EXECUTE 

    --compute cA
    EXECUTE matrixnummul('w',c);

    --compute W=cA-aD
    EXECUTE matrixadd('w','diagonal');
    
    --loop until converge or maximum iterations
    LOOP
        --compute next Wp
        EXECUTE gimv();

        --add to belief vector
        EXECUTE vectoradd($4,'tmpprior');
    END LOOP;
END
$body$ LANGUAGE plpgsql;
