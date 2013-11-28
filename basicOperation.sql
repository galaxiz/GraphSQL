/*
 * Basic Operations
 *
 * Xi Zhao
 */

/*
 * GIM-V Implementation.
 * 
 * Input: the name of tables and name of functions.
 * E: matrix. V: original vector. V2: update vector.
 * C2: Combine2. CALL: combineAll. ASSIGN: assign
 * REVERSE: whether treat the edges in matrix in oppsite direction
 * 
 * Output: return value is number of updated rows.
 *
 * Xi Zhao
 */
CREATE OR REPLACE FUNCTION gimv(E TEXT,V TEXT,V2 TEXT, C2 TEXT, 
    CAll TEXT, ASSIGN TEXT, REVERSE INTEGER) RETURNS INTEGER AS $body$
DECLARE
row_affected integer;
BEGIN   
    IF $7=0 THEN
        EXECUTE format($s$
            Update %s AS tar
            set val=%s(tar.val,tmp.val)
            FROM    (
                SELECT m.sid as id, %s(%s(m.val,v.val)) as val
                FROM %s AS m,%s AS v
                WHERE m.did=v.id
                GROUP BY m.sid
            ) as tmp
            where tar.id=tmp.id and tar.val!=%s(tar.val,tmp.val);
            $s$,$3,$6,$5,$4,$1,$2,$6);
    ELSE
        EXECUTE format($s$
            Update %s AS tar
            set val=%s(tar.val,tmp.val)
            FROM    (
                SELECT m.did as id, %s(%s(m.val,v.val)) as val
                FROM %s AS m,%s AS v
                WHERE m.sid=v.id
                GROUP BY m.did
            ) as tmp
            where tar.id=tmp.id and tar.val!=%s(tar.val,tmp.val);
            $s$,$3,$6,$5,$4,$1,$2,$6);
    END IF;
    GET DIAGNOSTICS row_affected=ROW_COUNT;
    RETURN row_affected;
END
$body$ LANGUAGE plpgsql;


/*
 * Multiplication bewteen matrix and scalar number
 */
CREATE OR REPLACE FUNCTION matrixnummul(target text,num numeric) RETURNS VOID AS $body$
BEGIN
    EXECUTE format($s$
        UPDATE %s AS TAR
        SET val=TAR.val*%s;
        $s$,$1,$2);
END
$body$ LANGUAGE plpgsql;

/*
 * Multiplication bewteen vector and scalar number
 */
CREATE OR REPLACE FUNCTION vectornummul(target text,num numeric) RETURNS VOID AS $body$
BEGIN
    EXECUTE format($s$
        UPDATE %s AS TAR
        SET val=TAR.val*%s;
        $s$,$1,$2);
END
$body$ LANGUAGE plpgsql;

/*
 * vector addition
 * add two vector 
 */
CREATE OR REPLACE FUNCTION vectoradd(targetvector text,adder text) RETURNS VOID AS $body$
BEGIN
    EXECUTE format($s$
        UPDATE %s AS TAR
        SET val=(TAR.val+AER.val)
        FROM %s AS AER
        WHERE TAR.id=AER.id;
        $s$,$1,$2);
END
$body$ LANGUAGE plpgsql;

/*
 * matrix addition
 * add two matrix 
 */
CREATE OR REPLACE FUNCTION maxtrixadd(targetmatrix text,adder text) RETURNS VOID AS $body$
BEGIN
    EXECUTE format(
        'UPDATE %s AS TAR
        SET val=(TAR.val+AER.val)
        FROM %s AS AER
        WHERE TAR.sid=AER.sid and TAR.did=AER.did;'
        ,$1,$2);
END
$body$ LANGUAGE plpgsql;

/*
 * load data
 * Create table and loading matrix data from file.
 */
CREATE OR REPLACE FUNCTION loaddata(filename text,tablename text,val integer) RETURNS VOID AS $body$
BEGIN
    EXECUTE format(
        'CREATE TABLE %s(sid integer, did integer, val numeric default 1);'
        , $2);
    IF val=0 THEN
        EXECUTE format(
            $$COPY %s(sid,did) FROM '%s' WITH DELIMITER ' '$$
            ,$2,$1);
    ELSE
        EXECUTE format(
            $$COPY %s(sid,did,val) FROM '%s' WITH DELIMITER ' '$$
            ,$2,$1);
    END IF;
END
$body$ LANGUAGE plpgsql;

/*
 * load data with integer
 * Create table and loading matrix data from file.
 */
CREATE OR REPLACE FUNCTION loaddata_int(filename text,tablename text,val integer) RETURNS VOID AS $body$
BEGIN
    EXECUTE format(
        'CREATE TABLE %s(sid integer, did integer, val integer);'
        , $2);
    IF val=0 THEN
        EXECUTE format(
            $$COPY %s(sid,did) FROM '%s' WITH DELIMITER ' '$$
            ,$2,$1);
    ELSE
        EXECUTE format(
            $$COPY %s(sid,did,val) FROM '%s' WITH DELIMITER ' '$$
            ,$2,$1);
    END IF;
END
$body$ LANGUAGE plpgsql;

/*
 * vector length
 */
CREATE OR REPLACE FUNCTION vectorlen(v text) RETURNS numeric AS $body$
DECLARE
    len numeric:=0;
BEGIN
    --compute length
    EXECUTE format($s$
        SELECT sum(val*val)
        FROM %s
        $s$, $1) INTO len;

    RETURN sqrt(len);
END
$body$ LANGUAGE plpgsql;

/*
 * Matrix matrix multiplication
 */
CREATE OR REPLACE FUNCTION matrixmulr(target text,multiplier text,tp integer) RETURNS VOID AS $body$
BEGIN
    IF $3=0 THEN
        EXECUTE format($s$
            UPDATE %s AS tar
            SET val=(
                SELECT sum(one.val*two.val)::numeric(256,128)
                FROM %s AS one,%s AS two
                WHERE one.sid=tar.sid and two.did=tar.did and one.did=two.sid
            )
            $s$,$1,$1,$2);
    ELSE
        EXECUTE format($s$
            UPDATE %s AS tar
            SET val=(
                SELECT sum(one.val*two.val)::numeric(256,128)
                FROM %s AS one,%s AS two
                WHERE one.sid=tar.sid and two.sid=tar.did and one.did=two.did
            )
            $s$,$1,$1,$2);
    END IF;
END
$body$ LANGUAGE plpgsql;

/*
 * Matrix matrix multiplication
 */
CREATE OR REPLACE FUNCTION matrixmull(multiplier text,target text,tp integer) RETURNS VOID AS $body$
BEGIN
    IF $3=0 THEN
        EXECUTE format($s$
            UPDATE %s AS tar
            SET val=(
                SELECT sum(one.val*two.val)::numeric(256,128)
                FROM %s AS one,%s AS two
                WHERE one.sid=tar.sid and two.did=tar.did and one.did=two.sid
            )
            $s$,$2,$1,$2);
    ELSE
        EXECUTE format($s$
            UPDATE %s AS tar
            SET val=(
                SELECT sum(one.val*two.val)::numeric(256,128)
                FROM %s AS one,%s AS two
                WHERE one.did=tar.sid and two.did=tar.did and one.sid=two.sid
            )
            $s$,$2,$1,$2);
    END IF;
END
$body$ LANGUAGE plpgsql;

/*
 * make zero vector
 */
CREATE OR REPLACE FUNCTION zerovector(text,bigint) RETURNS VOID AS $body$
DECLARE
    i bigint:=1;
BEGIN
    EXECUTE format($s$
        DROP TABLE IF EXISTS %s;
        $s$,$1);

    EXECUTE format($s$
        CREATE TABLE %s(id int,val numeric);
        $s$,$1);

    LOOP
        IF i>$2 THEN
            EXIT;
        END IF;

        EXECUTE format(
            'INSERT INTO %s values(%s,0);'
            ,$1,i);

        i:=i+1;
    END LOOP;
END
$body$ LANGUAGE plpgsql;

/*
 * assume it has been created and has the same dimension
 */
CREATE OR REPLACE FUNCTION vectorcopy(source text,target text) RETURNS VOID AS $body$
BEGIN
    --assume it has been created and has the same dimension
    EXECUTE format($s$
        UPDATE %s AS tar
        SET val=src.val
        FROM %s AS src
        WHERE tar.id=src.id;
        $s$,$2,$1);
END
$body$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION vectordot(text,text) RETURNS numeric AS $body$
DECLARE
    res numeric:=0;
BEGIN
    EXECUTE format($s$
        SELECT sum(one.val*two.val)
        FROM %s AS one,%s AS two
        WHERE one.id=two.id;
        $s$,$1,$2) INTO res;

    RETURN res;
END
$body$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION col(matrix text,col integer,vector text) RETURNS VOID AS $body$
BEGIN
    PERFORM zerovector($3);

    EXECUTE format($s$
        UPDATE %s AS tar
        SET val=src.val
        FROM %s AS src
        WHERE tar.id=src.sid and src.did=$1
        $s$,$3,$1) USING $2;
END
$body$ LANGUAGE plpgsql;

