/*
 * Count triangles using wedge sampling
 *
 * Xi Zhao
 */

/*
 * main function
 */
CREATE OR REPLACE FUNCTION compute_tri(matrix text,vector text,sample bigint) RETURNS numeric AS $$
DECLARE
    i bigint; --loop
    cid bigint; --node (id) count
    p bigint; --total weight
    rand numeric; --rand 
    r bigint; --randomly chosen id (row)
    row_affected bigint;
    wedge bigint := 0; --wedge number in samples
    c bigint; --count of chosen
    sa numeric[];
BEGIN
    --init
    DROP TABLE IF EXISTS ischosen;
    EXECUTE format(
        'DROP TABLE IF EXISTS %s;'
        ,$2);

    --assume that each edge are splited into two edges and stored in table
    EXECUTE format(
        'SELECT count(*) FROM (SELECT distinct sid FROM %s UNION SELECT distinct did FROM %s) as U'
        ,$1,$1) INTO cid;
    EXECUTE new_vector_tri($2,cid);

    RAISE NOTICE 'Compute wedges of each node';
    --compute how many wedges each node has.
    EXECUTE format(
        'INSERT INTO %s
        SELECT TMP.sid AS id,count(*)*(count(*)-1)/2 AS val
        FROM %s AS TMP
        WHERE TMP.val=1
        GROUP BY TMP.sid;'
        ,$2,$1);
    /*
    --assume only one direction is stored
    EXECUTE format(
        'INSERT INTO %s
        SELECT TMP.sid AS id,count(*)*(count(*)-1)/2 AS val
        FROM (
            SELECT did AS sid,sid AS did FROM %s UNION ALL 
            SELECT sid,did FROM %s
        ) AS TMP
        GROUP BY TMP.sid;'
        ,$2,$1,$1);
    */

    --total probability
    EXECUTE format(
        'SELECT sum(val) FROM %s'
        ,$2) INTO p;

    --partial sum
    RAISE NOTICE 'Compute probability of each node';
    EXECUTE calc_sum($2,cid);

    --select sample k nodes
    RAISE NOTICE 'Sampling...';
    CREATE TEMP TABLE ischosen(id integer,val numeric);

    i:=1;
    LOOP
        rand:=random()*p;
        --RAISE NOTICE 'Rand:%',rand;
        --row
        EXECUTE format(
            'SELECT min(id) FROM %s WHERE val> %s'
            ,$2,rand) INTO r;

        --check chosen
        PERFORM * FROM ischosen WHERE id=r;
        GET DIAGNOSTICS row_affected=ROW_COUNT;

        --if already chosen
        IF row_affected =0 THEN
            --update
            RAISE NOTICE 'Add %th randomly chosed: %',i,r;
            INSERT INTO ischosen values(r,1);
        ELSE 
            UPDATE ischosen AS tar
            SET val=tar.val+1
            WHERE tar.id=r;
        END IF;

        i:=i+1;
        IF i>$3 THEN
            EXIT;
        END IF;
    END LOOP;
    
    --for each node choose a wedge uniformly
    r:=1;
    LOOP
        /*
        PERFORM * FROM ischosen WHERE id=r;
        GET DIAGNOSTICS row_affected=ROW_COUNT;
        */

        SELECT val INTO c FROM ischosen WHERE id=r;

        --IF row_affected!=0 THEN
        IF c IS NOT NULL THEN
            LOOP
                /*
                EXECUTE format(
                    'SELECT did
                    FROM (
                        SELECT did, random() as weight FROM (
                            SELECT did AS sid,sid AS did FROM %s UNION ALL 
                            SELECT sid,did FROM %s
                        ) as U
                        WHERE U.sid=%s
                        ORDER BY weight
                        LIMIT 1
                    ) as TBL'
                    ,$1,$1,r) INTO s1;
                 */
                EXECUTE format(
                    'SELECT array_agg(did)
                    FROM (
                        SELECT did, random() as weight FROM %s as U
                        WHERE U.sid=%s
                        ORDER BY weight
                        LIMIT 2
                    ) as TBL'
                    ,$1,r) INTO sa;

                --check whether triangle
                RAISE NOTICE 'check: r:% s1:% s2:%',r,sa[1],sa[2];

                /*
                EXECUTE format(
                    'SELECT * 
                    FROM %s
                    WHERE (sid=%s and did=%s) or (sid=%s and did=%s)'
                    ,$1,s1,s2,s2,s1);
                 */
                EXECUTE format(
                    'SELECT * 
                    FROM %s
                    WHERE sid=%s and did=%s'
                    ,$1,sa[1],sa[2]);
                GET DIAGNOSTICS row_affected=ROW_COUNT;

                --if triangle
                IF row_affected!=0 THEN
                    --RAISE NOTICE 'triangle.';
                    wedge:=wedge+1;
                END IF;

                c:=c-1;
                IF c<=0 THEN
                    EXIT;
                END IF;
            END LOOP;
        END IF;

        r:=r+1;
        IF r>cid THEN
            EXIT;
        END IF;
    END LOOP;

    --get triangle count from global clustering coefficient
    RETURN wedge*p/3.0/$3;
END
$$ LANGUAGE plpgsql;

/*
 * number of wedges
 */
CREATE OR REPLACE FUNCTION new_vector_tri(text,bigint) RETURNS VOID AS $$
DECLARE
    i integer := 1;
BEGIN
    EXECUTE format(
        'CREATE TABLE %s(id integer, val numeric);'
        , $1);
END
$$ LANGUAGE plpgsql;

/*
 * caculate partial sum
 * even this function is too slow for big data.
 */
CREATE OR REPLACE FUNCTION calc_sum(text,bigint) RETURNS VOID AS $$
DECLARE 
    i bigint:=2;
    ida integer[];
    vala numeric[];
BEGIN
    EXECUTE format($s$
        SELECT array(SELECT id FROM %s order by id)
        $s$,$1) INTO ida;
    
    EXECUTE format($s$
        SELECT array(SELECT val FROM %s order by id)
        $s$,$1) INTO vala;

    i:=2;
    LOOP
        vala[i]:=vala[i-1]+vala[i];
        --RAISE NOTICE 'update:%',i;
        i:=i+1;
        IF i>array_length(vala,1) THEN
            EXIT;
        END IF;
    END LOOP;

    EXECUTE format($s$
        UPDATE %s AS tar
        SET val=n.val
        FROM (
            SELECT unnest($1) AS id,unnest($2) AS val
        ) AS n
        WHERE tar.id=n.id;
        $s$,$1) USING ida,vala;
    
    /*
    --too slow
    LOOP
        RAISE NOTICE 'update:%',i;
        EXECUTE format(
            'UPDATE %s
            SET val=%s.val + (
                SELECT tbl.val FROM %s tbl WHERE tbl.id=%s-1
            )
            WHERE %s.id=%s;'
            ,$1,$1,$1,i,$1,i);
        
        i:=i+1;
        IF i>$2 THEN
            EXIT;
        END IF;
    END LOOP;
    */
END
$$ LANGUAGE plpgsql;
