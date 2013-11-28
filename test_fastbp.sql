/*
 * Unit test for fast belief propagation
 */

CREATE OR REPLACE FUNCTION test_compute_bp() RETURNS VOID AS $body$
BEGIN
    CREATE TABLE test_bp(sid int,did int,val numeric);
    CREATE TABLE test_bp_p(id int,val numeric);

    INSERT INTO test_bp VALUES(1,1,);

    DROP TABLE test_bp;
    DROP TABLE test_bp_p;
END
$body$ LANGUAGE plpgsql;
