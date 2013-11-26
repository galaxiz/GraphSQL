/*
 * Compute radius 
 */

CREATE OR REPLACE FUNCTION compute_radii (E TEXT) RETURNS VOID AS $$
DECLARE
n INTEGER; --node number
changedlines INTEGER;
BEGIN
    --DROP TABLE IF EXISTS radius_edge;
    --CREATE TABLE IF EXISTS radius_edge (sid INTEGER, did INTEGER, val INTEGER);
    --EXECUTE loaddata (E,)
    n := numnodes('radius_edge');
    RAISE NOTICE 'The number of nodes are %', n;
    EXECUTE generatebitmask(n, 25);

    LOOP
        changedlines := gimv('radius_edge', 'bits', 'bits', 'radii_combine2', 'bit_or', 'radii_assign', 0);
        RAISE NOTICE 'Rows changed by: %', changedlines;

        IF changedlines = 0 THEN
            EXIT;
        END IF;
    END LOOP;

    EXECUTE gen_effradii();

END
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION gen_effradii() RETURNS VOID AS $$
BEGIN
    DROP TABLE IF EXISTS effradius;
    CREATE TABLE effradius (id INTEGER, val INTEGER);
    INSERT INTO effradius
        SELECT bits.id, find_least_zero_pos(bits.val) FROM bits;
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
    RAISE NOTICE 'RETURN %', 32;
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
