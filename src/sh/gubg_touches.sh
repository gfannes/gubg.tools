touches_fn=$HOME/gubg.sh
if [ -f $touches_fn ]
then
    echo ">> Executing local touches from $touches_fn ..."
    source $touches_fn
    echo "<< ... done"
else
    echo "Warning: No local touches file $touches_fn found."
fi
