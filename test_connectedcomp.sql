/*
 * Unit test for connected component
 */

CREATE OR REPLACE FUNCTION test_compute_cc() RETURNS integer AS $body$
DECLARE
    cc integer;
BEGIN
    CREATE TABLE test_cc(sid int,did int,val numeric);

    INSERT INTO test_cc values(1,2,1);
    INSERT INTO test_cc values(2,1,1);

    INSERT INTO test_cc values(2,3,1);
    INSERT INTO test_cc values(3,2,1);

    INSERT INTO test_cc values(3,1,1);
    INSERT INTO test_cc values(1,3,1);

    INSERT INTO test_cc values(4,5,1);
    INSERT INTO test_cc values(5,4,1);

    INSERT INTO test_cc values(5,6,1);
    INSERT INTO test_cc values(6,5,1);

    INSERT INTO test_cc values(7,6,1);
    INSERT INTO test_cc values(6,7,1);

    INSERT INTO test_cc values(6,8,1);
    INSERT INTO test_cc values(8,6,1);

    INSERT INTO test_cc values(6,9,1);
    INSERT INTO test_cc values(9,6,1);

    INSERT INTO test_cc values(8,9,1);
    INSERT INTO test_cc values(9,8,1);

    INSERT INTO test_cc values(10,9,1);
    INSERT INTO test_cc values(10,7,1);
    INSERT INTO test_cc values(10,11,1);
    INSERT INTO test_cc values(9,12,1);
    INSERT INTO test_cc values(12,13,1);
    INSERT INTO test_cc values(13,14,1);
    INSERT INTO test_cc values(12,14,1);

    INSERT INTO test_cc values(9,10,1);
    INSERT INTO test_cc values(7,10,1);
    INSERT INTO test_cc values(11,10,1);
    INSERT INTO test_cc values(12,9,1);
    INSERT INTO test_cc values(13,12,1);
    INSERT INTO test_cc values(14,13,1);
    INSERT INTO test_cc values(14,12,1);

    cc:=compute_cc('test_cc','test_cc_v');

    DROP TABLE test_cc;

    RETURN cc;
END
$body$ LANGUAGE plpgsql;
