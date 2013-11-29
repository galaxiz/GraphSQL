/*
 * eigenvalue
 * Lanczos
 * -bisection
 * -QR decomposition (deprecated)
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

    --new b
    EXECUTE new_rand_vector($3,$2);

    --init
    y[0]:=0;

    EXECUTE zerovector('v0',n);

    EXECUTE zerovector('v1',n);
    r:=vectorlen($2);
    EXECUTE vectornummul($2,1/r);
    EXECUTE vectorcopy($2,'v1');

    FOR i IN 1..$3 LOOP
        RAISE NOTICE 'round:%',i;
        --find a new basis vector
        EXECUTE zerovector('v',n);
        PERFORM gimv($1,format('v%s',i),'v','combine2_ev','sum','assign_ev',0);

        --dot product
        x[i]:=vectordot(format('v%s',i),'v');
        RAISE NOTICE 'alpha%:%',i,x[i];

        --RAISE NOTICE 'v:%',array(SELECT val FROM v ORDER BY id)::numeric(64,32)[];

        --orthogonalize against two previous basis vectors
        EXECUTE zerovector('tmp1',n);
        EXECUTE zerovector('tmp2',n);
        EXECUTE vectorcopy(format('v%s',i-1),'tmp1');
        EXECUTE vectorcopy(format('v%s',i),'tmp2');
        EXECUTE vectornummul('tmp1',-y[i-1]);
        EXECUTE vectornummul('tmp2',-x[i]);
        EXECUTE vectoradd('v','tmp1');
        EXECUTE vectoradd('v','tmp2');

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
        FOR j IN 1..i LOOP
            --if less then orthogonalize
            IF y[i]*abs(ele('q',i,j)) <= sqrt($4)*det('t') THEN
                isorth=TRUE;

                EXECUTE col('q',j,'tmp1');

                EXECUTE gimv('vm','tmp1','tmp1','c2','ca','as',0);

                r=vectordot('tmp1','v');
                EXECUTE vectornummul('tmp1',-r);
                EXECUTE vectoradd('v','tmp1');
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

        RAISE NOTICE ' ';
    END LOOP;

    RAISE NOTICE 'Starting build triangle';
    --build tri-diagonal matrix
    EXECUTE tridiagonal($3,x,y,'t');

    --eigen decomposition
    PERFORM eig($3,'t','q','d',$3::int);

    --top k diagonal elements (eigenvalues)
    k:=array(SELECT val FROM d WHERE sid=did ORDER BY abs(val) desc);

    EXECUTE format($s$
        CREATE TABLE IF NOT EXISTS %s(id integer,val numeric);
        $s$,$5);

    EXECUTE format($s$
        TRUNCATE TABLE %s;
        $s$,$5);

    --put k in vector
    EXECUTE format($s$
        INSERT INTO %s
        SELECT sid AS id,val AS val 
        FROM %s
        WHERE sid=did
        ORDER BY abs(val) DESC
        $s$,$5,'d');

    RETURN k;
END
$body$ LANGUAGE plpgsql;

/*
 * qr decomposition
 * some bugs / replaced by bisection().
 */
CREATE OR REPLACE FUNCTION qr(dim bigint,source text,q text) RETURNS VOID AS $body$
DECLARE 
    r numeric(128,64)[][];
BEGIN
    EXECUTE format($s$
        CREATE TABLE IF NOT EXISTS %s(sid integer,did integer,val numeric);
        $s$,$3);

    EXECUTE format($s$
        TRUNCATE TABLE %s;
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

/*
 * bisection
 * ideas from 
 * http://www.mathworks.com/matlabcentral/fileexchange/
 * 38303-linear-algebra-package/content/
 * Linear%20Algebra%20Methods/
 */
CREATE OR REPLACE FUNCTION bisection(dim bigint,source text) RETURNS numeric[] AS $body$
DECLARE
    d numeric[];
    od numeric[];
    odsqr numeric[];
    m1 integer;
    m2 integer;
    emin numeric;
    emax numeric;
    h numeric;
    errBnd numeric;
    e numeric[];
    wu numeric[];
    eps numeric;
    eps1 numeric;
    its numeric;
    e0 numeric;
    eu numeric;
    e1 numeric;
    a numeric;
    q numeric;
    i integer;
    k integer;
BEGIN
    EXECUTE format($s$
        SELECT array_agg(u.val)
        FROM (
            SELECT tmp.val
            FROM %s AS tmp
            WHERE tmp.sid=tmp.did
            ORDER BY tmp.sid
        ) AS u
        $s$,$2) INTO d;

    EXECUTE format($s$
        SELECT array_agg(u.val)
        FROM (
            SELECT tmp.val
            FROM %s AS tmp
            WHERE tmp.sid=tmp.did+1
            ORDER BY tmp.sid
        ) AS u
        $s$,$2) INTO od;

    od[0]:=0;

    FOR i IN 0..dim-1 LOOP
        odsqr[i]:=od[i]*od[i];
    END LOOP;
    
    emin:=d[dim]-abs(od[dim-1]);
    emax:=d[dim]+abs(od[dim-1]);

    eps:=0.000000000000000000000000001;
    eps1:=0.000001;

    FOR rev IN 1..dim-1 LOOP
        i:=dim-rev;
        h:=abs(od[i-1])+abs(od[i]);
        
        IF (d[i]+h)>emax THEN
            emax:=d[i]+h;
        END IF;

        IF (d[i]-h)<emin THEN
            emin:=d[i]-h;
        END IF;
    END LOOP;

    IF (emin+emax)>0 THEN
        errBnd:=eps*emax;
    ELSE
        errBnd:=eps*(-emin);
    END IF;

    --if (eps1 <= 0)
        --eps1 = errBnd;

    errBnd:=0.5*eps1+7*errBnd;
    e0:=emax;
    --wu = zeros(m2,1);
    --e = zeros(m2,1);
    FOR i IN 1..dim LOOP
        wu[i]:=emin;
        e[i]:=emax;
    END LOOP;

    its := 0;
    FOR rev IN 1..dim LOOP
        k:= dim+1-rev;
        eu := emin;
        FOR rev2 IN 1..k LOOP
            i:=k+1-rev2;
            IF eu < wu[i] THEN
                eu := wu[i];
                EXIT;
            END IF;
        END LOOP;

        IF e0 > e[k] THEN
            e0 := e[k];
        END IF;

        WHILE (e0 - eu) > 2 * eps * (abs(eu) + abs(e0)) + eps1 LOOP
            e1 := (eu+e0)/2;
            its := its + 1;
            a := 0;
            q := 1;
            --for i := 1:n
            FOR i IN 1..dim LOOP
                if q != 0 then
                    q := d[i] - e1 - odSqr[i-1] / q;
                else
                    q := d[i] - e1 - abs(od[i-1]) / eps;
                end if;
                if q < 0 then
                    a := a + 1;
                end if;
            end loop;
            if a < k then
                if a < 1 then
                    eu := e1;
                    wu[1] := e1;
                else
                    eu := e1;
                    wu[a+1] := e1;
                    if (e[a] > e1) then
                        e[a] := e1;
                    end if;
                end if;
            else
                e0 := e1;
            end if;
        end loop;
        e[k] := (e0 + eu) / 2;
    end loop;

    RETURN e;
END
$body$ LANGUAGE plpgsql;

/*
 * do eig decomposition
 */
CREATE OR REPLACE FUNCTION eig(dim bigint,source text,q text,d text,k integer) RETURNS numeric[] AS $body$
DECLARE
    e numeric[];
BEGIN
    --create d
    EXECUTE format($s$
        CREATE TABLE IF NOT EXISTS %s(sid integer,did integer,val numeric);
        $s$,$4);

    EXECUTE format($s$
        TRUNCATE TABLE %s;
        $s$,$4);

    --copy source to d
    EXECUTE format($s$
        INSERT INTO %s
        SELECT *
        FROM %s;
        $s$,$4,$2);

    /*
    --iteration to get d
    --not accurate, so deprecated
    FOR i IN 1..50 LOOP
        RAISE NOTICE 'qr round:%',i;
        PERFORM qr($1,$4,$3);

        PERFORM matrixmulr($4,$3,0);
        PERFORM matrixmull($3,$4,1);
    END LOOP;
    */
    e:=bisection($1,$4);

    --insert into d;
    FOR i IN 1..dim LOOP
        EXECUTE format($s$
            INSERT INTO %s
            VALUES($1,$1,$2)
            $s$,$4) USING i,e[i];
    END LOOP;
    
    RETURN e;
END
$body$ LANGUAGE plpgsql;

/*
 * build tridiagonal function
 */
CREATE OR REPLACE FUNCTION tridiagonal(dim bigint,x numeric[],y numeric[],matrix text) RETURNS VOID AS $body$
DECLARE
    id numeric[];
BEGIN
    EXECUTE format($s$
        CREATE TABLE IF NOT EXISTS %s(sid integer,did integer,val numeric);
        $s$,$4);

    EXECUTE format($s$
        TRUNCATE TABLE %s;
        $s$,$4);

    --init id
    FOR i IN 1..dim LOOP
        id[i]:=i;
    END LOOP;

    EXECUTE format($s$
        INSERT INTO %s
        SELECT unnest($1) AS sid,unnest($1) AS did,unnest($2) AS val
        $s$,$4) USING id,$2;

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

/*
 * combine2 function
 */
CREATE OR REPLACE FUNCTION combine2_ev(numeric,numeric) RETURNS numeric AS $body$
BEGIN
    RETURN $1*$2;
END
$body$ LANGUAGE plpgsql;

/*
 * assign function
 */
CREATE OR REPLACE FUNCTION assign_ev(numeric,numeric) RETURNS numeric AS $body$
BEGIN
    RETURN $2;
END
$body$ LANGUAGE plpgsql;

/*
 * new random vector
 */
CREATE OR REPLACE FUNCTION new_rand_vector(dim bigint,text) RETURNS VOID AS $body$
BEGIN
    EXECUTE format($s$
        CREATE TABLE IF NOT EXISTS %s(id integer,val numeric);
        $s$,$2);

    EXECUTE format($s$
        TRUNCATE TABLE %s;
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
