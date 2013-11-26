/*
 * Generate small graph for test
 * 
 * Xi Zhao
 */

/*
 * test case for count triangle wedge sampling
 * 1. no triangle 2. all nodes formed triangle 3. in the middle.
 */
CREATE OR REPLACE FUNCTION test_gen_matrix(option text) RETURNS VOID AS $body$
BEGIN
    DROP TABLE IF EXISTS testmatrix;

    CREATE TABLE testmatrix(sid integer,did integer,val numeric);

    --insert graph
    IF $1 = 'cc' THEN
        INSERT INTO testmatrix values(1,2,1);
        INSERT INTO testmatrix values(2,3,1);
        INSERT INTO testmatrix values(3,1,1);
        INSERT INTO testmatrix values(4,5,1);
        INSERT INTO testmatrix values(5,6,1);
        INSERT INTO testmatrix values(7,6,1);
        INSERT INTO testmatrix values(6,8,1);
        INSERT INTO testmatrix values(6,9,1);
        INSERT INTO testmatrix values(8,9,1);
        INSERT INTO testmatrix values(10,9,1);
        INSERT INTO testmatrix values(10,7,1);
        INSERT INTO testmatrix values(10,11,1);
        INSERT INTO testmatrix values(9,12,1);
        INSERT INTO testmatrix values(12,13,1);
        INSERT INTO testmatrix values(13,14,1);
        INSERT INTO testmatrix values(12,14,1);
    ELSIF $1 = 'tri0' THEN 
        INSERT INTO testmatrix values(1,2,1);
        INSERT INTO testmatrix values(2,3,1);
        INSERT INTO testmatrix values(4,5,1);
        INSERT INTO testmatrix values(5,6,1);
        INSERT INTO testmatrix values(7,6,1);
        INSERT INTO testmatrix values(6,8,1);
        INSERT INTO testmatrix values(6,9,1);
        INSERT INTO testmatrix values(10,9,1);
        INSERT INTO testmatrix values(10,7,1);
        INSERT INTO testmatrix values(10,11,1);
        INSERT INTO testmatrix values(9,12,1);
        INSERT INTO testmatrix values(12,13,1);
        INSERT INTO testmatrix values(12,14,1);
    ELSIF $1 = 'tria' THEN
        INSERT INTO testmatrix values(1,2,1);
        INSERT INTO testmatrix values(3,2,1);
        INSERT INTO testmatrix values(1,3,1);
        INSERT INTO testmatrix values(4,2,1);
        INSERT INTO testmatrix values(1,4,1);
        INSERT INTO testmatrix values(3,4,1);
        INSERT INTO testmatrix values(5,6,1);
        INSERT INTO testmatrix values(6,7,1);
        INSERT INTO testmatrix values(5,7,1);
    ELSIF $1 = 'bp' THEN
        DROP TABLE IF EXISTS testprior(id integer, val numeric);

        CREATE TABLE testprior(id integer,val numeric);

        --matrix

        --prior
    END IF;
END
$body$ LANGUAGE plpgsql;
