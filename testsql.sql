CREATE OR REPLACE FUNCTION bitwise_or(B1 TEXT) RETURNS VOID AS $$
DECLARE 
i INTEGER;
BEGIN
    i = 2|1;
    INSERT INTO bit VALUES(4,i); 
END
$$ LANGUAGE plpgsql;

-- Generate a bit string for each node

