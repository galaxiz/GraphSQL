/*
 * Compute radius 
 * E: input table name
 * K: K copies of bits
 */

CREATE OR REPLACE FUNCTION compute_radii (E TEXT, K INTEGER) RETURNS VOID AS $$
DECLARE
n INTEGER; --node number
changedlines INTEGER;
iter INTEGER;
maxiter INTEGER;
BEGIN
    --DROP TABLE IF EXISTS radius_edge;
    --CREATE TABLE IF EXISTS radius_edge (sid INTEGER, did INTEGER, val INTEGER);
    --EXECUTE loaddata (E,)
    n := numnodes('rd_edge');
    RAISE NOTICE 'The number of nodes are %', n;

    iter := 0;

    DROP TABLE IF EXISTS bitmap_tmp;
    CREATE TEMP TABLE bitmap_tmp (iteration INTEGER, id INTEGER, val INTEGER);
    DROP TABLE IF EXISTS leftzeromap;
    CREATE TABLE leftzeromap (iteration INTEGER, id INTEGER, val INTEGER, cnt INTEGER);

    FOR j IN 1..K LOOP
        iter := 0;
        EXECUTE generatebitmask(n, 22);
        LOOP
            changedlines := gimv('rd_edge', 'bits', 'bits', 'radii_combine2', 'bit_or', 'radii_assign', 0);
            RAISE NOTICE 'Rows changed by: %', changedlines;

            -- store all data in bitmap
            iter := iter + 1;
            RAISE NOTICE 'ITERATION %', iter;
            INSERT INTO bitmap_tmp SELECT iter, bits.id, bits.val FROM bits;

            IF changedlines = 0 THEN
                EXIT;
            END IF;
        END LOOP;
        IF j = 1 THEN
            RAISE NOTICE 'here';
            INSERT INTO leftzeromap 
                SELECT iteration, bitmap_tmp.id, find_least_zero_pos(bitmap_tmp.val), 1 FROM bitmap_tmp;
            maxiter := iter;
        ELSE
            IF maxiter < iter THEN
                maxiter := iter;
            END IF;
            UPDATE leftzeromap 
                SET val = leftzeromap.val + find_least_zero_pos(bitmap_tmp.val),
                cnt = cnt + 1
            FROM
                bitmap_tmp
            WHERE
                bitmap_tmp.id = leftzeromap.id and bitmap_tmp.iteration = leftzeromap.iteration;
        END IF;
    END LOOP;

    UPDATE leftzeromap
        SET val = val/cnt;

    EXECUTE gen_effradii(maxiter);

END
$$ LANGUAGE plpgsql;

/*CREATE OR REPLACE FUNCTION gen_effradii(iter INTEGER) RETURNS VOID AS $$
BEGIN
    DROP TABLE IF EXISTS effradius;
    CREATE TABLE effradius (id INTEGER, val INTEGER);
    INSERT INTO effradius
        SELECT bits.id, find_least_zero_pos(bits.val) FROM bits;
    UPDATE effradius 
        SET val = convert_pos_to_radii(iter, id, val);
END
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION convert_pos_to_radii(iter INTEGER, idpos INTEGER, n INTEGER) RETURNS INTEGER AS
$$
DECLARE
nhmax NUMERIC;
pos INTEGER;
bitval INTEGER;
BEGIN
    --RAISE NOTICE 'ITERATION % idpos %', iter, idpos;
    nhmax := nh_from_pos(n);
    --find the smallest h such that n(h,i) >= 0.9*nhmax
    FOR x IN 1..iter LOOP
        SELECT INTO bitval val FROM bitmap WHERE iteration = x and id=idpos; 
        pos := find_least_zero_pos(bitval);
        IF nh_from_pos(pos) >= 0.9*nhmax THEN
            --RAISE NOTICE 'EFF radius %', x;
            RETURN x;
        END IF;
    END LOOP; 
END
$$ LANGUAGE plpgsql;
*/

-- optimized!!!!
CREATE OR REPLACE FUNCTION gen_effradii(iter INTEGER) RETURNS VOID AS $$
BEGIN
    DROP TABLE IF EXISTS effradius;
    CREATE TABLE effradius (id INTEGER, val INTEGER);
    INSERT INTO effradius SELECT id, 0 FROM bits;
    
    FOR x IN 1..iter LOOP
        UPDATE effradius
            SET val = x
        FROM 
            (SELECT T.id AS uid FROM 
            (SELECT id, nh_from_pos(val) AS nh FROM leftzeromap WHERE iteration = x) AS T, bits
            WHERE bits.id = T.id AND nh >= 0.9*nh_from_bitmask(bits.val)) RES 
        WHERE
            id = RES.uid AND val=0;
    END LOOP;
END
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION convert_pos_to_radii(iter INTEGER, idpos INTEGER, n INTEGER) RETURNS INTEGER AS
$$
DECLARE
nhmax NUMERIC;
pos INTEGER;
bitval INTEGER;
BEGIN
    --RAISE NOTICE 'ITERATION % idpos %', iter, idpos;
    nhmax := nh_from_pos(n);
    --find the smallest h such that n(h,i) >= 0.9*nhmax
    FOR x IN 1..iter LOOP
        SELECT INTO bitval val FROM bitmap WHERE iteration = x and id=idpos; 
        pos := find_least_zero_pos(bitval);
        IF nh_from_pos(pos) >= 0.9*nhmax THEN
            --RAISE NOTICE 'EFF radius %', x;
            RETURN x;
        END IF;
    END LOOP; 
END
$$ LANGUAGE plpgsql;



/*
 * GIMV operations
 */
CREATE OR REPLACE FUNCTION radii_combine2 (INTEGER, INTEGER) RETURNS INTEGER AS $$
BEGIN
    RETURN $1*$2;
END
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION radii_assign (INTEGER, INTEGER) RETURNS INTEGER AS $$
BEGIN   
    RETURN $1|$2;
END
$$ LANGUAGE plpgsql;

/*
 * Generate bit mask
 *
 * n is the number of nodes
 */
CREATE OR REPLACE FUNCTION generatebitmask (n INTEGER, s INTEGER) RETURNS VOID AS $$
BEGIN
    DROP TABLE IF EXISTS bits;
    CREATE TABLE bits (id INTEGER, val INTEGER);
    FOR i IN 0..n LOOP
        INSERT INTO bits VALUES (i, create_random_bm(s));
    END LOOP; 
END
$$LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION create_random_bm (s INTEGER) RETURNS INTEGER AS $$
DECLARE
cur_random NUMERIC;
thres NUMERIC;
mask INTEGER;
res INTEGER;
BEGIN
    cur_random := random();
    
    thres := 0;
    FOR j IN 0..(s-2) LOOP
        thres := thres + power(2, -1*j-1);

        IF (cur_random < thres) THEN
            mask := j;
            EXIT;
        END IF;   
    END LOOP; 
    
    res := 0;
    IF mask < s-1 THEN
        res := 1 << (s-1-mask) << (32-s);
    END IF;

    RETURN res;
END
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION find_least_zero_pos (num INTEGER) RETURNS INTEGER AS $$
DECLARE
mask INTEGER;
BEGIN
    FOR k IN 0..31 LOOP
        mask := 1<<(31-k);
        
        -- find the left most 0
        IF num & mask = 0 THEN
            RETURN k;
        END IF;
    END LOOP; 
    --RAISE NOTICE 'RETURN %', 32;
    RETURN 32;
END
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION nh_from_bitmask(n INTEGER) RETURNS NUMERIC AS $$
DECLARE
least_zero INTEGER;
BEGIN
    least_zero := find_least_zero_pos(n);
    RETURN power(2, least_zero)/0.77351;
END
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION nh_from_pos(n INTEGER) RETURNS NUMERIC AS $$
BEGIN
    RETURN power(2, n)/0.77351;
END
$$ LANGUAGE plpgsql;
