#!/bin/sh

die()
# Beauty death
# @Param : $1 = an epitaph.
# @Return : none.
{
    echo ""
    echo "$1"
    echo ""
    exit 1
}

parse()
# Change date in YY/MM/DD after take it if it's an CB event.
# @Param : $1 = 1st field (date).
#          $2 = 2nd field (label).
#          $3 = 3rd field (amount).
# @Return : $date;$label;$amount" string.
{
    date=$1
    label=$2
    amount=$3

#    echo "$date -> $label => $amount"

    echo $label | grep -q "ACHAT CB"
    if [ $? -eq 0 ]; then
        date=$(echo $label | sed -e "s/.*\([0-9][0-9]\)\.\([0-9][0-9]\)\.\([0-9][0-9]\) .*/20\3\/\2\/\1/")
    else
        date=$(echo $date | awk -F"/" '{ print $3"/"$2"/"$1}')
    fi

    label=$(echo $label | sed -e "s/\"//g ; s/ CARTE NUMERO 990 $//")
    amount="$amount EUR"

    echo "$date;$label;$amount"
}

verififCCP()
# Check if is really CCP account.
# @Param : $1 = csv file to check.
# @Return : 1 = it's CCP, etherelse 0
{
    r=$(grep -i "Type" LBP-20190505.csv | cut -d";" -f2 | tr -d "\n" | tr -d "\r")
    [[ $r == "CCP" ]] && return 1
    return 0
}

[ $# -eq 0 ] && die "With which file i should work ?"

[ ! -f $1 ] && die "Something wrong with $1!"

of=$1	        # Original file.
wf="workon_$of"	# Working file.
rf="result_$of"	# Resulting file.

verififCCP $of
[ $? -eq 0 ] && die "Not Postal Banck account ? At this time, I only parse it !"

# Don't work on original file.
cp -pv $of $wf

[ -f $rf ] && rm -v $rf
echo "New version of $rf created"
touch $rf

# Keep only "Solde" and amount.
str="Solde "
str=${str}$(grep -i "solde" $wf | grep -vi "franc" | sed "s/: /;/" | cut -d';' -f2 | sed "s/\s.*$//")
echo "$str EUR" >> $rf
# Searched pattern line number.
dateline=$(grep -n "Date;Lib" $wf)

# Remove lines beetween 1 and before line of "Date;Lib".
n=$(echo $dateline | cut -d':' -f1)
sed -i 1,$((n-1))"d" $wf
#sed $((n-1))"p" $wf >> $rf


# Write "Date;Lib..." in result file, an delete it from working file. And we don't need FRANCS anymore.
echo $dateline | cut -d':' -f2 | sed "s/;Montant(FRANCS)//" >> $rf
sed -i 1d $wf

# Read each lines left in working file.
while read line
do
#    echo $line >> $rf
    plist=$(echo $line | awk -F';' '{ print $1";"$2";"$3 }')

    old_IFS=$IFS

    # Separator become ";" instead of " "
    IFS=';'
    parse $plist >> $rf
#    echo "*******" >> $rf
    IFS=$old_IFS

done < $wf

#rm -v $wf

exit 0
