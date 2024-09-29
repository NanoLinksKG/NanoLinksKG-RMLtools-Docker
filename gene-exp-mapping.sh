#!/bin/bash

HOME_PATH=/data
APP_PATH=/app

# # Do some cleaning
# cd $HOME_PATH/ENM_public_data
# # Delete all files and folders starting with "._" which they are junk files
# find . -type f -name \\._* -exec rm {} \;
# # Delete all files for unfiltered genes
# find . -type f -name *Unfiltered_DEG.xlsx -exec rm {} \;

yarrrml-parser -i $HOME_PATH/mapping/metadata.yml -o $HOME_PATH/mapping/ttl/metadata.ttl
yarrrml-parser -i $HOME_PATH/mapping/material.yml -o $HOME_PATH/mapping/ttl/material.ttl
yarrrml-parser -i $HOME_PATH/mapping/bioassay-lite.yml -o $HOME_PATH/mapping/ttl/bioassay-lite.ttl
yarrrml-parser -i $HOME_PATH/mapping/endpoints-contrast.yml -o $HOME_PATH/mapping/ttl/endpoints-contrast.ttl

for d in $HOME_PATH/ENM_public_data/* ; do

    if [ -d "$d" ]; then

		echo "$d"

		for dd in $d/*; do

			echo "$dd"

			#rm -rf $dd/csv
			#mkdir -p $dd/csv
			rm -rf $dd/rdf
			mkdir -p $dd/rdf

			cd $dd

			rm -rf ._*_Filtered_DEG.xlsx

			for metafile in *_metadata.txt; do
			
				if [ -f *_metadata.txt ]; then
					
					echo "$metafile"
					awk 'BEGIN { FS="\t"; OFS="," } {$1=$1; print}' $metafile > metadata.csv

					\cp -f $HOME_PATH/mapping/ttl/metadata.ttl ./metadata.ttl
					
					java -Xmx8G -jar $APP_PATH/rmlmapper.jar -m metadata.ttl -o rdf/data-metadata.nq  -f $APP_PATH/functions.ttl -d
					
					rm metadata.ttl
					
					\cp -f $HOME_PATH/mapping/ttl/material.ttl ./material.ttl
					
					java -Xmx8G -jar $APP_PATH/rmlmapper.jar -m material.ttl -o rdf/data-material.nq  -f $APP_PATH/functions.ttl -d
					
					rm material.ttl
					
					\cp -f $HOME_PATH/mapping/ttl/bioassay-lite.ttl ./bioassay-lite.ttl
					
					java -Xmx8G -jar $APP_PATH/rmlmapper.jar -m bioassay-lite.ttl -o rdf/data-bioassay-lite.nq  -f $APP_PATH/functions.ttl -d
					
					rm bioassay-lite.ttl
					
					
					# We are using the lightweight model where the original gene expressions of the samples genes are not mapped
					# if you want to map those, uncomment the following lines 
					
					#\cp -f $HOME_PATH/mapping/ttl/bioassay.ttl ./bioassay.ttl
					#java -Xmx8G -jar $APP_PATH/rmlmapper.jar -m bioassay.ttl -o rdf/data-bioassay.nq  -f $APP_PATH/functions.ttl -d
					#rm bioassay.ttl
				fi
			done

			for file in *_Filtered_DEG.xlsx; do	
				if [ -f *_Filtered_DEG.xlsx ]; then
					echo "$file"
					# This should be done once, because some of the sheets names should be fixed to match the contrast names
					# doing this command everytime will override the contrasts' fixed names
					#ssconvert -S $file csv/%s.csv
				fi
			done
		
			# multiline comment, Use : ' to open and ' to close
			
			: '
			cd Expression
		   
			rm -rf $dd/Expression/rdf
			mkdir -p $dd/Expression/rdf
		   
			for expression in *.csv; do
		
				\cp -f $HOME_PATH/mapping/ttl/endpoints.ttl ./endpoints.ttl
				
				echo "${expression}"
				
				GSM=${expression%.*}
				sed -i -e "s/@GSM@/${GSM}/" endpoints.ttl				
				java -Xmx8G -jar $APP_PATH/rmlmapper.jar -m endpoints.ttl -o rdf/data-${GSM}.nq  -f $APP_PATH/functions.ttl -d

				rm endpoints.ttl
				
			done
			
			cd ..
			
			'
			
			if [[ -d $dd/Filtered_DEG_csv ]]; then
			
				cd Filtered_DEG_csv
			   
				rm -rf $dd/Filtered_DEG_csv/rdf
				mkdir -p $dd/Filtered_DEG_csv/rdf
			   
				for contrast in *.csv; do
					
					\cp -f $HOME_PATH/mapping/ttl/endpoints-contrast.ttl ./endpoints-contrast.ttl
					
					echo "${contrast}"
					
					gseTemp=${dd##*/}
					GSE=${gseTemp%_files}
					CONTRAST=${contrast%.*}
					LEFT_GROUP="$(cut -d'-' -f1 <<<"$CONTRAST")"
					RIGHT_GROUP="$(cut -d'-' -f2 <<<"$CONTRAST")"
					
					sed -i -e "s/@CONTRAST@/${CONTRAST}/" -e "s/@GSE@/${GSE}/" -e "s/@LEFT_GROUP@/${LEFT_GROUP}/" -e "s/@RIGHT_GROUP@/${RIGHT_GROUP}/" endpoints-contrast.ttl

					java -Xmx8G -jar $APP_PATH/rmlmapper.jar -m endpoints-contrast.ttl -o rdf/data-gene-${CONTRAST}.nq  -f $APP_PATH/functions.ttl -d

					rm endpoints-contrast.ttl				
					
				done
				
				cd ..

			else
				echo "DEG is not there ${dd}"
			fi
			
		done
    fi
done

find $HOME_PATH/ENM_public_data -name data*.nq -exec cat {} + > $HOME_PATH/rdf/allData.nq

cd $HOME_PATH/rdf && tar -vczf allData.tar.gz allData.nq && rm $HOME_PATH/rdf/allData.nq

#cd $HOME_PATH/ENM_public_data && find . -type f -name *.nq -exec rm {} \;