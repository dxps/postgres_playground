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

load_dotenv('pgadmin_writer_master.env')

DB_HOST = os.getenv('DB_HOST', 'localhost')
DB_PORT = int(os.getenv('DB_PORT', '5432'))
DB_NAME = os.getenv('DB_NAME', 'postgres')
DB_USER = os.getenv('DB_USER', 'postgres')
DB_PASS = os.getenv('DB_PASS', 'postgres')
CONNECT_TIMEOUT = 5

connectionString = "host=%s port=%i dbname=%s user=%s password=%s connect_timeout=%i" % (DB_HOST, DB_PORT, DB_NAME, DB_USER, DB_PASS, CONNECT_TIMEOUT)

# Execute Insert statement against table if doDML is true.
# Create a table in advance, see the notes above.
doDML = True

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
            # Check if connected to Master or Replica.
            cur.execute("select pg_is_in_recovery(),inet_server_addr()")
            rows = cur.fetchone()
            if (rows[0] == False):
               print ("[writer master] Working with MASTER - %s" % rows[1], end=""),
               if doDML:
                  cur.execute("INSERT INTO HATEST VALUES(CURRENT_TIMESTAMP) RETURNING TM")
                  if cur.rowcount == 1 :
                     conn.commit()
                     tmrow = str(cur.fetchone()[0])
                     print ('| Inserted: %s\n' % tmrow, end="")
               else:
                  print ("[writer master] No attempt to insert data.")
            else:
               print ("[writer master] Working with REPLICA - %s" % rows[1], end=""),
               if doDML:
                  cur.execute("SELECT MAX(TM) FROM HATEST")
                  row = cur.fetchone()
                  print ("| Retrived: %s\n" % str(row[0]), end="")
               else:
                  print ("No Attempt to retrive data")

         except:
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

