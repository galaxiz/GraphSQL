/*
 * Basic Operations
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
 *
 * Xi Zhao
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
 *
 * Xi Zhao
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
 *
 * Xi Zhao
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
 *
 * Xi Zhao
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
 *
 * Xi Zhao
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
 *
 * Xi Zhao
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
 * 
 * Xi Zhao
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
 * Xi Zhao
 */
CREATE OR REPLACE FUNCTION matrixmul(target text,multiplier text) RETURNS VOID AS $body$
BEGIN
END
$body$ LANGUAGE plpgsql;

/*
 * make zero vector
 */
CREATE OR REPLACE FUNCTION zerovector(text) RETURNS VOID AS $body$
BEGIN
    --set vector to be zero vector;
END
$body$ LANGUAGE plpgsql;
