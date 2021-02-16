#/bin/bash
#by: Luis F. Duque
# Newcastle University
# 14/02/2021

#############################################################
#############################################################
# Description

# Aim: to download records from the GHCN-daily in a tidy format
# The inputs are : 
# 1) the initial and final years of the record length, 
# 2) the acronyms of the daily environmental variables, and 
# 3) the code of the stations
# The acronyms of the daily variables are:
# PRCP: Precipitation (tenths of mm)
# SNOW: Snowfall (mm)
# TMAX: Maximum temperature (tenths of degrees C)
# TMIN: Minimum temperature (tenths of degrees C)
# SNOW: Snowfall (mm)
# SNWD = Snow depth (mm)
# The codes of the stations can be checked in https://www1.ncdc.noaa.gov/pub/data/ghcn/daily/ghcnd-stations.txt

#############################################################
#############################################################
# Requirements
# To run the script, one must install csvkit in the shell. 
# The path environment must set as: ./local/bin
# to set the PATH one can use the following code: 
# if [ -d "$HOME/.local/bin" ] ; then
# PATH="$HOME/.local/bin:$PATH"
# fi

#############################################################
#############################################################
# Development

#############################################################
# Define variables

Start=$1
End=$2

# Define enviromental variables from the user

read -p "Enter Variables separated by 'space' : " Var
read -p "Enter station/s code separated by 'space' : " Stat

#############################################################
# Create folders


mkdir -p Outputs


cd Outputs

mkdir ${Var[@]}

mkdir All

cd ..

#############################################################
# Download files

for ((i=Start; i<=End; i++))
do
   wget -P ./Outputs/All ftp://ftp.ncdc.noaa.gov/pub/data/ghcn/daily/by_year/$i.csv.gz 
   gunzip ./Outputs/All/$i.csv.gz
done

#############################################################
# Select data according Station
cd Outputs/All

for k in ${Stat[@]}

do

for ((i=Start; i<=End; i++))
	do
         csvgrep -c 1 -m ${k} $i.csv | csvcut -c 1,2,3,4 > Aux1.csv
         echo Sta_Code,Date,Var,Value | cat - Aux1.csv > Aux_${k}_$i.csv  
         
         csvcut -c 2 Aux_${k}_$i.csv | cut -c1-4 > year.csv
         csvcut -c 2 Aux_${k}_$i.csv | cut -c5-6 > month.csv
         csvcut -c 2 Aux_${k}_$i.csv | cut -c7-8 > day.csv
         
         paste -d, Aux_${k}_$i.csv year.csv month.csv day.csv > Aux1_${k}_$i.csv
         sed -i '1s/.*/Sta_cod,Date,Var,Value,Year,Month,Day/' Aux1_${k}_$i.csv
         cut -d, -f2 --complement Aux1_${k}_$i.csv >  Aux2_${k}_$i.csv
         awk -F ',' 'BEGIN{OFS=",";} {print $1, $2, $4, $5, $6, $3}' Aux2_${k}_$i.csv > ${k}_$i.csv
         rm year.csv month.csv day.csv Aux_${k}_$i.csv Aux1_${k}_$i.csv Aux2_${k}_$i.csv  
          


        done
done

rm Aux1.csv

#############################################################
# Move files to each variable's folder

cd ..
cd ..


for k in ${Stat[@]}
do
	for j in ${Var[@]}
	do

		for ((i=Start; i<=End; i++))
		do
	        cp Outputs/All/${k}_$i.csv Outputs/${j}
 		done

	done
done


#############################################################
# Filter by variable

for k in ${Stat[@]}
do

	for j in ${Var[@]}
	do
        cd Outputs/${j}

		for ((i=Start; i<=End; i++))
		do
		csvgrep -c 2 -m ${j} ${k}_$i.csv > ${k}_${j}_$i.csv
                rm ${k}_$i.csv   
   		done
       
     cd ..
     cd ..

      done
done


#############################################################
# Merge files


for k in ${Stat[@]}
do
	for j in ${Var[@]}
	do
	
         cd Outputs/${j}
       awk '(NR == 1) || (FNR > 1)' ${k}_*.csv > Aux_${j}_${k}.csv
       sed 's/\.[0-9]*"$/"/' Aux_${j}_${k}.csv > ${j}_${k}.csv
       rm ${k}_*.csv Aux_${j}_${k}.csv
     cd ..
     cd ..


      done
done
rm -r Outputs/All
#############################################################
#############################################################


