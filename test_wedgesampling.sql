/*
 * Unit test for triangle couting (wedge sampling)
 *
 */

CREATE OR REPLACE FUNCTION test_compute_tri() RETURNS numeric AS $body$
DECLARE
    count numeric;
BEGIN
    /* 5 triangles */
    CREATE TABLE test_tri(sid int,did int,val numeric);

    INSERT INTO test_tri VALUES(1,1,0);
    INSERT INTO test_tri VALUES(1,2,1);
    INSERT INTO test_tri VALUES(1,3,1);
    INSERT INTO test_tri VALUES(1,4,1);
    INSERT INTO test_tri VALUES(1,5,0);
    INSERT INTO test_tri VALUES(1,6,0);
    INSERT INTO test_tri VALUES(1,7,0);

    INSERT INTO test_tri VALUES(2,1,1);
    INSERT INTO test_tri VALUES(2,2,0);
    INSERT INTO test_tri VALUES(2,3,1);
    INSERT INTO test_tri VALUES(2,4,1);
    INSERT INTO test_tri VALUES(2,5,0);
    INSERT INTO test_tri VALUES(2,6,0);
    INSERT INTO test_tri VALUES(2,7,0);
    
    INSERT INTO test_tri VALUES(3,1,1);
    INSERT INTO test_tri VALUES(3,2,1);
    INSERT INTO test_tri VALUES(3,3,0);
    INSERT INTO test_tri VALUES(3,4,1);
    INSERT INTO test_tri VALUES(3,5,0);
    INSERT INTO test_tri VALUES(3,6,0);
    INSERT INTO test_tri VALUES(3,7,0);

    INSERT INTO test_tri VALUES(4,1,1);
    INSERT INTO test_tri VALUES(4,2,1);
    INSERT INTO test_tri VALUES(4,3,1);
    INSERT INTO test_tri VALUES(4,4,0);
    INSERT INTO test_tri VALUES(4,5,0);
    INSERT INTO test_tri VALUES(4,6,0);
    INSERT INTO test_tri VALUES(4,7,0);

    INSERT INTO test_tri VALUES(5,1,0);
    INSERT INTO test_tri VALUES(5,2,0);
    INSERT INTO test_tri VALUES(5,3,0);
    INSERT INTO test_tri VALUES(5,4,0);
    INSERT INTO test_tri VALUES(5,5,0);
    INSERT INTO test_tri VALUES(5,6,1);
    INSERT INTO test_tri VALUES(5,7,1);

    INSERT INTO test_tri VALUES(6,1,0);
    INSERT INTO test_tri VALUES(6,2,0);
    INSERT INTO test_tri VALUES(6,3,0);
    INSERT INTO test_tri VALUES(6,4,0);
    INSERT INTO test_tri VALUES(6,5,1);
    INSERT INTO test_tri VALUES(6,6,0);
    INSERT INTO test_tri VALUES(6,7,1);

    INSERT INTO test_tri VALUES(7,1,0);
    INSERT INTO test_tri VALUES(7,2,0);
    INSERT INTO test_tri VALUES(7,3,0);
    INSERT INTO test_tri VALUES(7,4,0);
    INSERT INTO test_tri VALUES(7,5,1);
    INSERT INTO test_tri VALUES(7,6,1);
    INSERT INTO test_tri VALUES(7,7,0);

    count:=compute_tri('test_tri','test_tri_v',10);

    DROP TABLE test_tri;
    DROP TABLE test_tri_v;

    RETURN count;
END
$body$ LANGUAGE plpgsql;
