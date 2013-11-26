/*
 * eigenvalue
 * 
 * Xi Zhao
 */

CREATE OR REPLACE FUNCTION compute_ev(matrix text,randv text,iteration bigint,error numeric,valuev text) RETURNS VOID AS $body$
DECLARE
    i bigint;
    j bigint;
BEGIN
    --init

    i:=1
    LOOP
        --find a new basis vector

        --dot product

        --orthogonalize against two previous basis vectors

        --length

        --build tri-diagonal matrix

        --eigen decomposition

        --selective orthogonalize
        j:=1
        LOOP
            --if less then orthogonalize
            IF THEN
            END IF;

            j:=j+1
            IF j>i THEN
                EXIT;
            END IF;
        END LOOP;

        --if orthogonalized
        IF THEN
        END IF;

        --converge
        IF THEN 
        END IF;

        --set v_{i+1}

        i:=i+1
        IF i>$3 THEN
            EXIT;
        END IF;
    END LOOP;

    --build tri-diagonal matrix

    --eigen decomposition

    --top k diagonal elements (eigenvalues)
END
$body$ LANGUAGE plpgsql;
