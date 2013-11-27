/*
 * eigenvalue
 * 
 * Xi Zhao
 */

CREATE OR REPLACE FUNCTION compute_ev(matrix text,randv text,iteration bigint,error numeric,valuev text) RETURNS VOID AS $body$
DECLARE
    i bigint;
    j bigint;
    x numeric[];
    y numeric[];
    k numeric[];
    isorth boolean;
    r numeric;
BEGIN
    --init
    y[0]:=0;
    EXECUTE zerovector('v0');
    r:=vectorlen($2);
    EXECUTE vectornummul($2,1/r);
    EXECUTE vectorcopy($2,'v1');

    i:=1;
    LOOP
        --find a new basis vector
        EXECUTE gimv($1,format('v%s',i),'v','c2','ca','as',0);

        --dot product
        x[i]:=vectordot(format('v%s',i),'v');

        --orthogonalize against two previous basis vectors
        EXECUTE vectornummul(format('v%s',i-1),-y[i-1],'tmp1');
        EXECUTE vectornummul(format('v%s',i),-x[i],'tmp2');
        EXECUTE vectoradd('v','tmp1');
        EXECUTE vectoradd('v','tmp2');

        --length
        y[i]:=vectorlen('v');

        --build tri-diagonal matrix
        EXECUTE tridiagonal(i,x,y,format('t%s',i));

        --eigen decomposition
        EXECUTE eig('t','q','d');

        --selective orthogonalize
        isorth:= FALSE;
        j:=1;
        LOOP
            --if less then orthogonalize
            IF y[i]*abs(ele('q',i,j)) <= sqrt($4)*det('t') THEN
                isorth=TRUE;

                EXECUTE col('q',j,'tmp1');

                EXECUTE gimv('vm','tmp1','tmp1','c2','ca','as',0);

                r=vectordot('tmp1','v');
                EXECUTE vectornummul('tmp1',-r);
                EXECUTE vectoradd('v','tmp1');
            END IF;

            j:=j+1;
            IF j>i THEN
                EXIT;
            END IF;
        END LOOP;

        --if orthogonalized
        IF THEN
        END IF;

        --converge
        IF isorth THEN 
            y[i]:=vectorlen('v');
        END IF;

        --set v_{i+1}
        EXECUTE vectornummul('v',1/y[i]);
        EXECUTE vectorcopy('v',format('v%s',i+1));

        i:=i+1;
        IF i>$3 THEN
            EXIT;
        END IF;
    END LOOP;

    --build tri-diagonal matrix
    EXECUTE tridiagonal(i,x,y,format('t%s',i));

    --eigen decomposition
    EXECUTE eig('t','q','d');

    --top k diagonal elements (eigenvalues)
    k:=array(SELECT val FROM d ORDER BY val desc);
END
$body$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION eig(source text,q text,d text) RETURNS VOID AS $body$
BEGIN
END
$body$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION tridiagonal(size integer,x numeric[],y numeric[],matrix text) RETURNS VOID AS $body$
BEGIN
END 
$body$ LANGUAGE plpgsql;
