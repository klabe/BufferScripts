#!/bin/bash

# This script handles pushing files to the nfs server on nlug.
# It watches several directories and scp's new files as they
# become available.  The code is based on the L2 client.

# Specifying where things are located--------------
## directories holding the data to ship
burstdir=/raid/data/burst
l1dir=/raid/data/l1
l2dir=/raid/data/l2
## filelist files
LSl1=/home/trigger/BufferScripts/nlug/lsl1.txt
LSl2=/home/trigger/BufferScripts/nlug/lsl2.txt
LSburst=/home/trigger/BufferScripts/nlug/lsburst.txt
FLl1=/home/trigger/BufferScripts/nlug/fll1.txt
FLl2=/home/trigger/BufferScripts/nlug/fll2.txt
FLburst=/home/trigger/BufferScripts/nlug/flburst.txt
## nlug stuff
NLUG=192.168.80.138
l2dest=/raid/data/l2
l1dest=/raid/data/zdab
burstdest=/raid/data/burst
#--------------------------------------------------

# This function updates the text files holding the lists of files
# available on the buffer, and the lists of files we have already
# shipped to nlug.
updatefilelists(){
# Get the list of files available to ship
## L1
find $l1dir | grep .zdab > nlugtemp.txt
sort nlugtemp.txt > $LSl1
rm nlugtemp.txt
## L2
find $l2dir | grep .zdab > nlugtemp.txt
sort nlugtemp.txt > $LSl2
rm nlugtemp.txt
## Bursts
find $burstdir | grep .zdab > nlugtemp.txt
sort nlugtemp.txt > $LSburst
rm nlugtemp.txt

# If there is no $FL file, assume we want to ship everything available
if [ ! -f $FLl1 ]
then
  cp $LSl1 $FLl1
fi
if [ ! -f $FLl2 ]
then
  cp $LSl2 $FLl2
fi
if [ ! -f $FLburst ]
then
  cp $LSburst $FLburst
fi

# Drop files from $FL no longer in $LS
comm -12 $LSl1 $FLl1 > nlugtemp.txt
sort nlugtemp.txt > $FLl1
rm nlugtemp.txt

comm -12 $LSl2 $FLl2 > nlugtemp.txt
sort nlugtemp.txt > $FLl2
rm nlugtemp.txt

comm -12 $LSburst $FLburst > nlugtemp.txt
sort nlugtemp.txt > $FLburst
rm nlugtemp.txt
}

# MAIN
while true
do
  updatefilelists
  # L1
  if [ $(comm -23 $LSl1 $FLl1 | wc -l) -gt 0 ]
  then
    FILE=$(ls -t $(comm -23 $LSl1 $FLl1) | head -n 1)
    scp $FILE $NLUG:$l1dest/$FILE 
  fi
  # L2
  if [ $(comm -23 $LSl2 $FLl2 | wc -l) -gt 0 ]
  then
    FILE=$(ls -t $(comm -23 $LSl2 $FLl2) | head -n 1)
    scp $FILE $NLUG:$l2dest/$FILE
  fi
  # bursts
  if [ $(comm -23 $LSburst $FLburst | wc -l) -gt 0 ]
  then
    FILE=$(ls -t $(comm -23 $LSburst $FLburst) | head -n 1)
    scp $FILE $NLUG:$burstdest/$FILE
  fi
  # Don't sleep for too long to reduce latency in getting burst
  # files to nlug
  sleep 1
done
