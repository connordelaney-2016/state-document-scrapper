#!/bin/bash

URL=https://www.mass.gov/doc/tax-lien-cases/download
THE_DATE=$(date +%Y-%m-%d)
PDF_NAME="ServiceMembers-${THE_DATE}.pdf"
TEXT_OUTPUT_NAME=convertedPdf.txt
COMMA_FILE_NAME="ServiceMembers-${THE_DATE}.csv"


# Download pdf
curl -o $PDF_NAME https://www.mass.gov/doc/tax-lien-cases/download


# Convert pdf to text
pdftotext -layout $PDF_NAME $TEXT_OUTPUT_NAME


TITLE=$(cat $TEXT_OUTPUT_NAME | grep "Cases Filed" | head -n1)
echo "Title=$TITLE"

# Strip out noise
cat $TEXT_OUTPUT_NAME  \
    | grep -v "Case Group" \
    | grep -v "Land Court" \
    | grep -v "Cases Filed" \
    | grep -v "Commonwealth" \
    | grep -v "Click Here" \
    | grep -v "Case Type" \
    | grep -v "Case Number" \
    | grep -v "End of Report"  \
    | grep -v "Case Number" > test.txt
cat test.txt  | grep -v "^$"          > test2.txt  # Clean out empty lines
#cp test2.txt $TEXT_OUTPUT_NAME

# Convert comma in file to space
cat test2.txt | sed 's/,/ /g' > test3.txt


# Put comma's in correct positions
cat test3.txt | sed 's/.\{27,27\}/&|/;s/.\{41,41\}/&|/;s/.\{54,54\}/&|/;s/.\{87,87\}/&|/;s/.\{124,124\}/&|/' > pipe_separated.txt
cp pipe_separated.txt $COMMA_FILE_NAME


# Strip out et al
sed 's/et al//g' pipe_separated.txt > test4.txt


# Strip out aka



# Re-arrange Columns in Document
echo "Street                  ,City      ,State      ,Name      ,Plantif      ,Probate      ,Date Filed      ,Case#" > arrange.csv
cat test4.txt | awk -F"|" \
                        '{ print $4"     ," $3"     ,"  "MA     ," $6"     ," $5"     ," "N      ,"$2"     ," $1
                         }'  \
			     >> arrange.csv



#cat $COMMA_FILE_NAME | awk -F, 'BEGIN {print "Street, City, State, Name, Proat, File Date, Case#"} {print $4"     ," $3"     ," "MA     ," $6"     ," $5"     ," $2"     ," $1}' > arrange.csv


# Remove temp files
#rm $TEXT_OUTPUT_NAME tmp.txt test.txt


