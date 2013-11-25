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
    CAll TEXT, ASSIGN TEXT, REVERSE INTEGER) RETURNS INTEGER AS $$
DECLARE
row_affected integer;
BEGIN   
    IF $7=0 THEN
        EXECUTE format(
            'Update %s
            set val=%s(%s.val,tmp.val)
            FROM    (SELECT %s.sid as id, %s(%s(%s.val,%s.val)) as val
                FROM %s,%s
                WHERE %s.did=%s.id
                GROUP BY %s.sid
            ) as tmp
            where %s.id=tmp.id and %s.val!=%s(%s.val,tmp.val);'
            ,$3,$6,$2,$1,$5,$4,$1,$2,$1,$2,$1,$2,$1,$3,$3,$6,$3);
    ELSE
        EXECUTE format(
            'Update %s
            set val=%s(%s.val,tmp.val)
            FROM    (SELECT %s.did as id, %s(%s(%s.val,%s.val)) as val
                FROM %s,%s
                WHERE %s.sid=%s.id
                GROUP BY %s.did
            ) as tmp
            where %s.id=tmp.id and %s.val!=%s(%s.val,tmp.val);'
            ,$3,$6,$2,$1,$5,$4,$1,$2,$1,$2,$1,$2,$1,$3,$3,$6,$3);
    END IF;
    GET DIAGNOSTICS row_affected=ROW_COUNT;
    RETURN row_affected;
END
$$ LANGUAGE plpgsql;


/*
 * load data
 * Create table and loading matrix data from file.
 *
 * Xi Zhao
 */
CREATE OR REPLACE FUNCTION loaddata(filename text,tablename text,val integer) RETURNS VOID AS $body$
BEGIN
    EXECUTE format(
        'CREATE TABLE %s(sid integer, did integer, val numeric);'
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
