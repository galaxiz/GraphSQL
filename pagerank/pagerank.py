#!/usr/bin/python
##
## This is the initial version of pagerank, which is extremely slow
##

import sys
import psycopg2

def node_number(tablename,cur):
        cmd="select count(*) from ( select distinct fromNode from {0} union select distinct toNode from {0}) as t".format(tablename)
        cur.execute(cmd)
        return cur.fetchone()[0]

def isConverged(cur, thres):
    print 'check if converge'
    cmd = "select SUM(p.val*p.val - pn.val*pn.val)\
    from pagerank as p, pagerank_new as pn where p.id = pn.id"
    cur.execute(cmd)
    result = cur.fetchone()[0]
    print 'result is ' + str(result)
    if (abs(result) <= thres ):
        return True
    else:
        return False

def main():
    dfactor = 0.85 #dampling factor

    #connect to the database
    dbconn = psycopg2.connect('dbname=mydb')
    dbconn.autocommit = True
    cur = dbconn.cursor()

    tablename = sys.argv[1]

    #normalize row from edge matrix
    cur.execute("create table if not exists pagerank (id integer, val real)")
    cur.execute("delete from pagerank")
    num = node_number(tablename ,cur)
    init = float(1/float(num))


    #initialize pagerank vector
    for i in range(1, num+1):
        cmd = "insert into pagerank VALUES ({0},{1})".format(i,init)
        cur.execute(cmd)

    #row normalize the edge matrix
    cur.execute("create table if not exists rownormEdge (fromNode integer, toNode integer, weight real) ")
    cur.execute("delete from rownormEdge")
    cmd = 'insert into rownormEdge(fromNode, ToNode, weight)\
    select fromNode, toNode, c from {0} inner join\
    (select fromNode as f , 1/cast(count(*) as real) as c from {0}\
            group by fromNode) as T on {0}.fromNode = T.f'.format(tablename)
    cur.execute(cmd)

    for x in range(1 , num+1):
        cmd = 'select SUM(rownormEdge.weight) from rownormEdge where rownormEdge.fromNode = {0}'.format(x)
        cur.execute(cmd)
        su = cur.fetchone()[0]
        if su == None:
            print 'lalalalal'
            for y in range(1, num+1):
                    cmd = 'insert into rownormEdge values ({0}, {1}, {2})'.format(x,y,init)
                    cur.execute(cmd)
    
    print 'start calculating pagerank';
    cur.execute("create table if not exists pagerank_new (id integer, val real)")
    cur.execute("delete from pagerank_new")

    #init page rank new
    for i in range(1, num+1):
        cmd = "insert into pagerank_new VALUES ({0},0)".format(i,init)
        cur.execute(cmd)

    start = False;

    while (isConverged(cur, 0.0001) == False):
        if start == True:
            cur.execute("delete from pagerank")
            cur.execute("insert into pagerank select * from pagerank_new")
            cur.execute("delete from pagerank_new")
            for i in range(1, num+1):
                cmd = "insert into pagerank_new VALUES ({0},0)".format(i)
                cur.execute(cmd)
        start = True
        print ('That\'s another iteration')

        cmd = 'update pagerank_new  \
                set\
                    val = T.res\
                from\
                    (select rownormEdge.toNode as e, SUM(({0}*rownormEdge.weight)*pagerank.val) as res\
                    from rownormEdge, pagerank where rownormEdge.fromNode = pagerank.id\
                    group by rownormEdge.toNode) as T\
                where\
                    id = T.e'.format(dfactor)
        cur.execute(cmd)

        cmd = 'update pagerank_new \
                set\
                    val = val + T.res\
                from\
                    (select pagerank.id as pid, c.sum as res\
                    from pagerank,\
                        (select SUM({0}*p.val) as sum from pagerank as p) as c\
                                ) as T\
                where\
                    id = T.pid'.format((1-dfactor)/float(num))
        
        cur.execute(cmd)
    cur.execute("delete from pagerank")
    cur.execute("insert into pagerank select * from pagerank_new")
    cur.execute(cmd)
    cur.execute("select * from pagerank_new")
    show = cur.fetchall()
    for s in show:
         print " ", s[0], " ", s[1]

if __name__ == '__main__':
    main()
