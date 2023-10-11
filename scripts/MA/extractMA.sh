#!/bin/bash

URL=https://www.mass.gov/doc/servicemember-cases/download
THE_DATE=$(date +%Y-%m-%d)
PDF_NAME="ServiceMembers-${THE_DATE}.pdf"
TEXT_OUTPUT_NAME=convertedPdf.txt
COMMA_FILE_NAME="ServiceMembers-${THE_DATE}.csv"

mkdir ./PAGES

# Function creates a New Page based on pattern searches in file
function create_page() {
    pageName="Page-$1.txt"
    StartPattern="Page $1"
    EndPattern="^Printed: "
    #echo "Creating Page './PAGES/$pageName' for StartPattern=$StartPattern  EndPattern=$EndPattern"
    sed -n "/$StartPattern/,/^Printed: /p" $2 > ./PAGES/$pageName
}

# Function finds the position of columns in file and adds pipe separators to the file
function add_separators() {
    pageName="./PAGES/Page-$1.txt"
    datePos=$(cat $pageName | grep "Filed Date" | head -1 | grep -aob "Filed Date" | awk -F: '{print $1}')    
    cityPos=$(cat $pageName | grep "Filed Date" | head -1 | grep -aob "City" | awk -F: '{print $1}')
    cityPos="$(($datePos + 12))"
    streetPos=$(cat $pageName | grep "Filed Date" | head -1 | grep -aob "  Street" | awk -F: '{print $1}')
    streetPos="$(($streetPos + 2))"    
    plaintiffPos=$(cat $pageName | grep "Filed Date" | head -1 | grep -aob "Plaintiff" | awk -F: '{print $1}')
    plaintiffPos="$(($plaintiffPos + 3))"        
    defendantPos=$(cat $pageName | grep "Defendant" | head -1 | grep -aob "Defendant" | awk -F: '{print $1}')
    defendantPos="$(($defendantPos + 4))"            
    echo "For $pageName date=$datePos city=$cityPos street=$streetPos plaintiff=$plaintiffPos defendant=$defendantPos"


    cat $pageName | sed "s/.\{$datePos,$datePos\}/&|/" > $pageName-DATE
    cat $pageName-DATE | sed "s/.\{$cityPos,$cityPos\}/&|/" > $pageName-CITY
    cat $pageName-CITY | sed "s/.\{$streetPos,$streetPos\}/&|/" > $pageName-STREET
    cat $pageName-STREET | sed "s/.\{$plaintiffPos,$plaintiffPos\}/&|/" > $pageName-PLAINTIFF
    cat $pageName-PLAINTIFF | sed "s/.\{$defendantPos,$defendantPos\}/&|/" > $pageName-DEFENDANT


    # Cleanup and rename final file back to original name
    mv $pageName-DEFENDANT $pageName
    rm -f $pageName-DATE $pageName-CITY $pageName-STREET $pageName-PLAINTIFF $pageName-DEFENDANT
}

# Function strips out characters NOT interested in
function strip_out_lines_convert_to_csv() {
    pageName="./PAGES/Page-$1.txt"

    # Strip out noise
    cat $pageName  \
        | grep -v "Case Group" \
        | grep -v "Commonwealth" \
        | grep -v "Printed: " \
        | grep -v "Land Court Department" \
        | grep -v "Land Cour" \
        | grep -v "Land * Department" \
        | grep -v "Land * Dep" \
        | grep -v "Commonwealth o" \
        | grep -v "Cases Fi" \
        | grep -v "Land Court" \
        | grep -v "Case Number" > test1.txt



    # Convert , in file to space
    # Convert | in file to comma
    cat test1.txt | sed 's/,/ /g' > test2.txt
    cat test2.txt | sed 's/|/,/g' > test3.txt    

    cp test3.txt $pageName
    rm -f test1.txt test2.txt test3.txt
}

# Concat pages into one file
function concat_pages() {
    pageName="./PAGES/Page-$1.txt"

    cat $pageName >> $2
}

# Clean Up
rm test*.txt

# Download pdf
curl -o $PDF_NAME $URL


# Convert pdf to text
pdftotext -layout $PDF_NAME $TEXT_OUTPUT_NAME

max_pages=$(grep "Page [0-9]" $TEXT_OUTPUT_NAME | awk '{print $NF}' | sort -n | tail -1)
echo "Total=$max_pages Pages "

#
# Loop thru document creating a new Page for each
#
for (( c=1; c<=$max_pages; c++))
do
    create_page $c $TEXT_OUTPUT_NAME
done

#
# Loop thru add Pipe Separators
#
for (( c=1; c<=$max_pages; c++))
do
    add_separators $c
done

#
# Loop thru strip out charactes convert to CSV
#
for (( c=1; c<=$max_pages; c++))
do
    strip_out_lines_convert_to_csv $c
done    

#
# Concat all pages into one
#
#TITLE=$(cat $TEXT_OUTPUT_NAME | grep "Cases Filed" | head -n1)
#echo "Title=$TITLE"
echo "Case# , Date      ,City      ,Street      ,Plantif      ,Defendant" > $COMMA_FILE_NAME
for (( c=1; c<=$max_pages; c++))
do
    concat_pages $c $COMMA_FILE_NAME
done    


# Remove temp files
#rm $TEXT_OUTPUT_NAME tmp.txt test1.txt
