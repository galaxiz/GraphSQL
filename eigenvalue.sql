/*
 * eigenvalue
 * 
 * Xi Zhao
 */

CREATE OR REPLACE FUNCTION compute_ev(matrix text,randv text,iteration bigint,error numeric,valuev text) RETURNS numeric[] AS $body$
DECLARE
    n bigint;
    i bigint;
    j bigint;
    x numeric(256,128)[];
    y numeric(256,128)[];
    k numeric(256,128)[];
    isorth boolean;
    r numeric;
BEGIN
    --compute n
    EXECUTE format($s$
        SELECT max(greatest(m.sid,m.did))
        FROM %s AS m;
        $s$,$1) INTO n;

    --init
    y[0]:=0;

    EXECUTE zerovector('v0',n);

    EXECUTE zerovector('v1',n);
    r:=vectorlen($2);
    EXECUTE vectornummul($2,1/r);
    EXECUTE vectorcopy($2,'v1');

    i:=1;
    LOOP
        RAISE NOTICE 'round:%',i;
        --find a new basis vector
        EXECUTE zerovector('v',n);
        PERFORM gimv($1,format('v%s',i),'v','combine2_ev','sum','assign_ev',0);

        --dot product
        x[i]:=vectordot(format('v%s',i),'v');
        RAISE NOTICE 'alpha%:%',i,x[i];

        --orthogonalize against two previous basis vectors
        --RAISE NOTICE 'v:%',array(SELECT val FROM v ORDER BY id)::numeric(64,32)[];

        EXECUTE zerovector('tmp1',n);
        EXECUTE zerovector('tmp2',n);
        EXECUTE vectorcopy(format('v%s',i-1),'tmp1');
        EXECUTE vectorcopy(format('v%s',i),'tmp2');
        EXECUTE vectornummul('tmp1',-y[i-1]);
        EXECUTE vectornummul('tmp2',-x[i]);
        EXECUTE vectoradd('v','tmp1');
        EXECUTE vectoradd('v','tmp2');

        --RAISE NOTICE 'v:%',array(SELECT val FROM v ORDER BY id)::numeric(64,32)[];
        --length
        y[i]:=vectorlen('v');
        RAISE NOTICE 'beta%:%',i,y[i];

        --Currently lanczos-NO
        /*
        --build tri-diagonal matrix
        EXECUTE tridiagonal(i,x,y,format('t%s',i));

        --eigen decomposition
        EXECUTE eig(format('t%s',i),'q','d');

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
        IF isorth THEN 
            y[i]:=vectorlen('v');
        END IF;

        --converge
        IF y[i]=0 THEN
            EXIT;
        END IF;
        */

        --set v_{i+1}
        EXECUTE zerovector(format('v%s',i+1),n);
        EXECUTE vectornummul('v',1/y[i]);
        EXECUTE vectorcopy('v',format('v%s',i+1));

        i:=i+1;
        IF i>$3 THEN
            EXIT;
        END IF;
        RAISE NOTICE ' ';
    END LOOP;

    RAISE NOTICE 'Starting build triangle';
    --build tri-diagonal matrix
    EXECUTE tridiagonal($3,x,y,'t');

    --eigen decomposition
    EXECUTE eig($3,'t','q','d',$3::int);

    --top k diagonal elements (eigenvalues)
    k:=array(SELECT val FROM d WHERE sid=did ORDER BY val desc);

    EXECUTE format($s$
        DROP TABLE IF EXISTS %s;
        $s$,$5);

    EXECUTE format($s$
        CREATE TABLE %s(id integer,val numeric);
        $s$,$5);

    --put k in vector
    EXECUTE format($s$
        INSERT INTO %s
        SELECT sid AS id,val AS val 
        FROM %s
        WHERE sid=did
        ORDER BY val DESC
        $s$,$5,'d');

    RETURN k;
END
$body$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION qr(dim bigint,source text,q text) RETURNS VOID AS $body$
DECLARE 
    r numeric(128,64)[][];
BEGIN
    EXECUTE format($s$
        DROP TABLE IF EXISTS %s;
        $s$,$3);

    EXECUTE format($s$
        CREATE TABLE %s(sid integer,did integer,val numeric);
        $s$,$3);

    --compute Q
    r:=array_fill(0,array[dim::int,dim::int]);
    FOR i IN 1..dim LOOP
        FOR j IN 1..dim LOOP
            r[i][j]:=0;
        END LOOP;
    END LOOP;

    --Q = A;
    FOR j IN 1..dim LOOP
        EXECUTE zerovector(format('q%s',j),dim);
        PERFORM col($2,j,format('q%s',j));
    END LOOP;

    FOR j IN 1..dim LOOP
        --R(j,j) = norm(Q(:,j));
        r[j][j]:=vectorlen(format('q%s',j));

        --Q(:,j) = Q(:,j)/R(j,j);
        PERFORM vectornummul(format('q%s',j),1/r[j][j]);

        FOR k IN j+1..dim LOOP
            --R(j,k) = Q(:,j)'*Q(:,k);
            r[j][k]:=vectordot(format('q%s',j),format('q%s',k));

            --Q(:,k) = Q(:,k) - R(j,k)*Q(:,j);
            EXECUTE zerovector('Rjk',dim);
            EXECUTE vectorcopy(format('q%s',j),'Rjk');
            PERFORM vectornummul('Rjk',-r[j][k]);
            PERFORM vectoradd(format('q%s',k),'Rjk');
        END LOOP;
    END LOOP;

    --real q
    FOR j IN 1..dim LOOP
        EXECUTE format($s$
            INSERT INTO %s
            SELECT id AS sid, $1 AS did,val AS val
            FROM %s
            $s$,$3,format('q%s',j)) USING j;
    END LOOP;
END
$body$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION eig(dim bigint,source text,q text,d text,k integer) RETURNS VOID AS $body$
BEGIN
    --create d
    EXECUTE format($s$
        DROP TABLE IF EXISTS %s;
        $s$,$4);

    EXECUTE format($s$
        CREATE TABLE %s(sid integer,did integer,val numeric);
        $s$,$4);

    --copy source to d
    EXECUTE format($s$
        INSERT INTO %s
        SELECT *
        FROM %s;
        $s$,$4,$2);

    --iteration to get d
    --TODO
    FOR i IN 1..50 LOOP
        PERFORM qr($1,$4,$3);

        PERFORM matrixmulr($4,$3,0);
        PERFORM matrixmull($3,$4,1);
    END LOOP;

    --compute real q
END
$body$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION tridiagonal(dim bigint,x numeric[],y numeric[],matrix text) RETURNS VOID AS $body$
DECLARE
    id numeric[];
BEGIN
    EXECUTE format($s$
        DROP TABLE IF EXISTS %s;
        $s$,$4);

    EXECUTE format($s$
        CREATE TABLE %s(sid integer,did integer,val numeric);
        $s$,$4);

    --init id
    FOR i IN 1..dim LOOP
        id[i]:=i;
    END LOOP;

    EXECUTE format($s$
        INSERT INTO %s
        SELECT unnest($1) AS sid,unnest($1) AS did,unnest($2) AS val
        $s$,$4) USING id,$2;

    --delete b[0]
    --RAISE NOTICE 'b:% b[2:dim]:%',$3,$3[1:dim];

    EXECUTE format($s$
        INSERT INTO %s
        SELECT unnest($1) AS sid,unnest($2) AS did,unnest($3) AS val
        $s$,$4) USING id[1:dim-1],id[2:dim],$3[1:dim-1];
    
    EXECUTE format($s$
        INSERT INTO %s
        SELECT unnest($2) AS sid,unnest($1) AS did,unnest($3) AS val
        $s$,$4) USING id[1:dim-1],id[2:dim],$3[1:dim-1];
END 
$body$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION combine2_ev(numeric,numeric) RETURNS numeric AS $body$
BEGIN
    RETURN $1*$2;
END
$body$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION assign_ev(numeric,numeric) RETURNS numeric AS $body$
BEGIN
    RETURN $2;
END
$body$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION new_b(dim bigint,text) RETURNS VOID AS $body$
BEGIN
    EXECUTE format($s$
        DROP TABLE IF EXISTS %s;
        $s$,$2);

    EXECUTE format($s$
        CREATE TABLE %s(id integer,val numeric);
        $s$,$2);

    --insert
    FOR i IN 1..dim LOOP
        EXECUTE format($s$
            INSERT INTO %s
            VALUES($1,random());
            $s$,$2) USING i;
    END LOOP;
END
$body$ LANGUAGE plpgsql;
