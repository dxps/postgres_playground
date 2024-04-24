#!/usr/bin/python3
############################### HAtester.py #####################################
#     Version 2.2    Jobin Augustine, Fernando Laudares Camargos (2017-2021)
#
# Program to test reads and writes in a PostgreSQL server, including
# connection retry on connection failure to test load-balancing capabilities
# 

# PREREQUISITES
# 1) PostgreSQL Python connector python3-psycopg2
# 2) Target table HATEST must have been created in advance:
#    CREATE TABLE HATEST (TM TIMESTAMP);
#    CREATE UNIQUE INDEX idx_hatext ON hatest (tm desc);
# 3) Monitor replication using SELECT tm FROM hatest ORDER BY tm DESC LIMIT 1; 

import sys
import os
from dotenv import load_dotenv

load_dotenv('hatest_reader_replica.env')

DB_HOST = os.getenv('DB_HOST', 'localhost')
DB_PORT = int(os.getenv('DB_PORT', '5432'))
DB_NAME = os.getenv('DB_NAME', 'postgres')
DB_USER = os.getenv('DB_USER', 'postgres')
DB_PASS = os.getenv('DB_PASS', 'postgres')
CONNECT_TIMEOUT = 5

connectionString = "host=%s port=%i dbname=%s user=%s password=%s connect_timeout=%i" % (DB_HOST, DB_PORT, DB_NAME, DB_USER, DB_PASS, CONNECT_TIMEOUT)

# USAGE 
#
# - Execution:
#    ./HAtester.py
#
# - Reconnection:
#    Ctrl+C will trigger a new connection to test load balancing.
#
# - Stop execution:
#    Ctrl+Z to pause the job, then terminate it with: kill %<job_id>
#
###############################################################################

import sys,time,psycopg2

def create_conn():
   try:
      conn = psycopg2.connect(connectionString)
   except psycopg2.Error as e:
      print("Error: Unable to connect due to:", e)
      sys.exit(1)
   return conn

if __name__ == "__main__":
   conn = create_conn()
   if conn is not None:
      cur = conn.cursor()
      while True:
         try:
            time.sleep(1)
            if conn is not None:
               cur = conn.cursor()
            else:
               raise Exception("Connection not ready")
            
            # Check if connected to Primary or a Replica.
            cur.execute("select pg_is_in_recovery(),inet_server_addr()")
            rows = cur.fetchone()
            if (rows[0] == False):
               print("[reader replica] Working with PRIMARY - %s" % rows[1], end=""),
            else:
               print("[reader replica] Working with REPLICA - %s" % rows[1], end=""),
            
            cur.execute("SELECT MAX(TM) FROM HATEST")
            row = str(cur.fetchone()[0])
            print(' | Retrieved: %s\n' % row, end="")

         except Exception as err:
            print(" Could not read data due to '%s'." % err.__str__().split('\n')[0])
            time.sleep(2)
            if conn is not None:
               print(" Disconnecting ...", end="")
               conn.close()
               print('done')
            conn = create_conn()
            if conn is not None:
                 print(" Connecting ...", end="")
                 cur = conn.cursor()
                 print('done')

   conn.close()
