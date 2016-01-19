
#/bin/bash
CHECKDISPLAY=0
DONE="no"

while [ "$DONE" == "no" ]
do
   out=$(xdpyinfo -display :$CHECKDISPLAY 2>&1)
   if [[ "$out" == name* ]] || [[ "$out" == Invalid* ]]
   then
      # command succeeded; or failed with access error;  display exists
      (( CHECKDISPLAY+=1 ))
   else
      # display doesn't exist
      DONE="yes"
   fi
done

echo "first available display is :$CHECKDISPLAY"

