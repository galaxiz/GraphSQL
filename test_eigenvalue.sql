/*
 * Unit test for eigenvalue.sql
 *
 * Xi Zhao
 */

CREATE OR REPLACE FUNCTION test_eig() RETURNS NUMERIC[] AS $body$
DECLARE
    ev numeric(64,32)[];
BEGIN 
    CREATE TABLE test_eig(sid int,did int,val numeric);

    INSERT INTO test_eig VALUES(1,1,3);
    INSERT INTO test_eig VALUES(1,2,5);
    INSERT INTO test_eig VALUES(1,3,1);
    INSERT INTO test_eig VALUES(2,1,6);
    INSERT INTO test_eig VALUES(2,2,2);
    INSERT INTO test_eig VALUES(2,3,7);
    INSERT INTO test_eig VALUES(3,1,2);
    INSERT INTO test_eig VALUES(3,2,1);
    INSERT INTO test_eig VALUES(3,3,5);

    PERFORM eig(3,'test_eig','test_eig_q','test_eig_d',3);

    ev=array(SELECT val FROM test_eig_d WHERE sid=did ORDER BY val DESC);

    DROP TABLE test_eig;
    DROP TABLE test_eig_d;
    DROP TABLE test_eig_q;

    RETURN ev;
END
$body$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION test_compute_ev() RETURNS NUMERIC[] AS $body$
DECLARE
    ev numeric(64,32)[];
BEGIN 
    CREATE TABLE test_ev(sid int,did int,val numeric);

    INSERT INTO test_ev VALUES(1,1,0);
    INSERT INTO test_ev VALUES(1,2,1);
    INSERT INTO test_ev VALUES(1,3,1);
    INSERT INTO test_ev VALUES(1,4,0);
    INSERT INTO test_ev VALUES(1,5,0);

    INSERT INTO test_ev VALUES(2,1,1);
    INSERT INTO test_ev VALUES(2,2,0);
    INSERT INTO test_ev VALUES(2,3,1);
    INSERT INTO test_ev VALUES(2,4,0);
    INSERT INTO test_ev VALUES(2,5,0);
    
    INSERT INTO test_ev VALUES(3,1,1);
    INSERT INTO test_ev VALUES(3,2,1);
    INSERT INTO test_ev VALUES(3,3,0);
    INSERT INTO test_ev VALUES(3,4,0);
    INSERT INTO test_ev VALUES(3,5,0);

    INSERT INTO test_ev VALUES(4,1,0);
    INSERT INTO test_ev VALUES(4,2,0);
    INSERT INTO test_ev VALUES(4,3,0);
    INSERT INTO test_ev VALUES(4,4,0);
    INSERT INTO test_ev VALUES(4,5,1);

    INSERT INTO test_ev VALUES(5,1,0);
    INSERT INTO test_ev VALUES(5,2,0);
    INSERT INTO test_ev VALUES(5,3,0);
    INSERT INTO test_ev VALUES(5,4,1);
    INSERT INTO test_ev VALUES(5,5,0);

    PERFORM new_rand_vector(5,'test_ev_b');
    ev:=compute_ev('test_ev','test_ev_b',5,0.1,'test_ev_v');

    DROP TABLE test_ev;
    DROP TABLE test_ev_b;
    DROP TABLE test_ev_v;

    RETURN ev;
END
$body$ LANGUAGE plpgsql;
