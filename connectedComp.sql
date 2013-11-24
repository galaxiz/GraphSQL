/*
 * connected components
 * 
 * Xi Zhao
 */

/*
 * new vector for computing connected component
 * each node i is in set i.
 */
CREATE OR REPLACE FUNCTION new_vector_cc(text,integer) RETURNS VOID AS $$
DECLARE
i integer := 1;
BEGIN   
    EXECUTE format(
        'DROP TABLE IF EXISTS %s;
        CREATE TABLE %s(id integer, val numeric);'
        ,$1,$1);
    LOOP
        IF i>$2 THEN
            EXIT;
        END IF;

        EXECUTE format(
            'INSERT INTO %s values(%s,%s);'
            ,$1,i,i);

        i:=i+1;
    END LOOP;
END
$$
LANGUAGE plpgsql;

/*
 * combine2 function
 */
CREATE OR REPLACE FUNCTION second_val_cc(numeric,numeric) RETURNS numeric AS $$
BEGIN
    return $2;
END
$$ LANGUAGE plpgsql;

/*
 * compute components
 */
CREATE OR REPLACE FUNCTION compute_cc(matrix text,vector text) RETURNS VOID AS $$
DECLARE
i integer;
BEGIN
    --get number of distinct nodes and create set vector

    --update
    LOOP
        i := gimv($1,$2,$2,'second_val_cc','min','least',0);
        -- for undirected graph, we need to a reverse direction as well.
        i := i + gimv($1,$2,$2,'second_val_cc','min','least',1);
        IF i=0 THEN
            EXIT;
        END IF;
    END LOOP;
END
$$ LANGUAGE plpgsql;