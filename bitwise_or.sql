

CREATE AGGREGATE bitwise_all (INTEGER) {
    SFUNC = sfunc;
    STYPE = INTEGER;
    FINALFUNC = sfunc;


}
