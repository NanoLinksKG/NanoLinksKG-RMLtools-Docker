#!/bin/bash

if [ $# -lt 2 ]; then
    echo
	echo "You should provide two arguments at least"
	echo
	echo "proper usage is like this:"
	echo
	echo "docker run -it rmltools yarrrml YML_FILE_NAME"
	echo
	echo "OR" 
	echo
	echo "docker run -it rmltools rmlmapper RML_MAPPING_FILE_NAME OUTPUT_FILE_NAME OTHER_ARGUMENTS"
	echo
	echo "OTHER_ARGUMENTS can be for example: -d -e METADATA_FILE_NAME -l triple"
    exit 1
fi

COMMAND=$1

if [ "$COMMAND" == "yarrrml" ]; then

	if [ $# != 2 ]; then
		echo "You should prvodie two arguments at least"
		exit 1
	fi
	
	ARGUMENTS=$2
	
	if [[ -d ${ARGUMENTS} ]]; then
		
		ymldir=${ARGUMENTS%/}
		
		for file in $ymldir/*.yml; do
		
			mkdir -p $ymldir/ttl
			
			filename=${file##*/}
		
			yarrrml-parser -i $file -o $ymldir/ttl/${filename%.*}.ttl

			if [ $? -eq 0 ]; then
				echo "Converting mapping file ${file} from YAML to TTL succeeded!"
			else
				echo "Converting mapping file ${file} FAILED!!"
			fi
		done
	else
		yarrrml-parser -i ${ARGUMENTS} -o ${ARGUMENTS%.*}.ttl

		if [ $? -eq 0 ]; then
			echo "Converting mapping file ${ARGUMENTS} from YAML to TTL succeeded!"
		else
			echo "Converting mapping file ${ARGUMENTS} FAILED!!"
		fi
	fi
	
elif [ "$COMMAND" == "rmlmapper" ]; then

	if [ $# -lt 3 ]; then
		echo "You should prvodie two arguments at least"
		exit 1
	fi
	
	ARGUMENTS=${@:4}
	MAPPING=$2
	OUTPUT=$3
	
	if [[ -d ${MAPPING} ]]; then
	
		ttldir=${MAPPING%/}
		
		if [[ -f ${OUTPUT} ]]; then
		
			OUTPUT=${OUTPUT%/*}
		fi
		
		OUTPUT=${OUTPUT%/}
		
		for file in $ttldir/*.ttl; do
	
			filename=${file##*/}
			
			java -Xmx8G -jar /app/rmlmapper.jar -f /app/functions.ttl -m $file -o ${OUTPUT}/${filename%.*}.nq ${ARGUMENTS}
	
			if [ $? -eq 0 ]; then
				echo "RDF generation using ${filename} SUCCEEDED"
			else
				echo "RDF generation ${filename} FAILED!!"
			fi
		done
	else
	
		java -Xmx8G -jar /app/rmlmapper.jar -f /app/functions.ttl -m ${MAPPING} -o ${OUTPUT} ${ARGUMENTS}
		
		if [ $? -eq 0 ]; then
			echo "RDF generation SUCCEEDED"
		else
			echo "RDF generation FAILED!!"
		fi	
	fi
	
elif [ "$COMMAND" == "geneExpressionConversion" ]; then

	SSCONVERT=$2
	
	/app/gene-exp-mapping.sh
	
	if [ $? -eq 0 ]; then
		echo "RDF generation SUCCEEDED"
	else
		echo "RDF generation FAILED!!"
	fi
fi