#!/bin/bash

#This script downloads epg files and merges them into one file.

## VARIABLES
BASEPATH="/complete/path/to/folder"


############## variables for dummyEPG creator
numberofchannels=3
declare -a a0=("Channel1.us" "Channel Name" "Programme Name" "Programme Description")
declare -a a1=("Channel2.us" "Channel 2 Name" "Programme 2 Name" "Programme 2 Description")
declare -a a2=("Channel3.us" "Channel 3 Name" "Programme 3 Name" "Programme 3 Description")
starttimes=("000000" "060000" "120000" "180000")
endtimes=("060000" "120000" "180000" "235900")
DUMMYFILENAME=xdummy.xml

LISTS=(
"http://link.to.list.1" 
"https://link.to.list.2.xml.gz"
"http://link.to.list.3.gz"
)

dummycreator() {
		today=$(date +%Y%m%d)
		tomorrow=$(date --date="+1 day" +%Y%m%d)
        numberofiterations=$(($numberofchannels - 1))
		echo '<?xml version="1.0" encoding="UTF-8"?>' > $BASEPATH/$DUMMYFILENAME
		echo '<tv generator-info-name="dummy" generator-info-url="https://dummy.com/">' >> $BASEPATH/$DUMMYFILENAME


		for i in $(seq 0 $numberofiterations) ;do # Number of Dummys -1 
			tvgid=a$i[0]
			name=a$i[1]
			echo '    <channel id="'${!tvgid}'">' >> $BASEPATH/$DUMMYFILENAME
			echo '        <display-name lang="pt">'${!name}'</display-name>' >> $BASEPATH/$DUMMYFILENAME
			echo '    </channel>' >> $BASEPATH/$DUMMYFILENAME
		done

		for i in $(seq 0 $numberofiterations) ;do
			tvgid=a$i[0]
			title=a$i[2]
			desc=a$i[3]
			for j in {0..3}; do
					echo '    <programme start="'$today${starttimes[$j]}' +0000" stop="'$today${endtimes[$j]}' +0000" channel="'${!tvgid}'">' >> $BASEPATH/$DUMMYFILENAME
					echo '        <title lang="pt">'${!title}'</title>' >> $BASEPATH/$DUMMYFILENAME
					echo '        <desc lang="pt">'${!desc}'</desc>' >> $BASEPATH/$DUMMYFILENAME
					echo '    </programme>' >> $BASEPATH/$DUMMYFILENAME
			done
			for j in {0..3}; do
					echo '    <programme start="'$tomorrow${starttimes[$j]}' +0000" stop="'$tomorrow${endtimes[$j]}' +0000" channel="'${!tvgid}'">' >> $BASEPATH/$DUMMYFILENAME
					echo '        <title lang="pt">'${!title}'</title>' >> $BASEPATH/$DUMMYFILENAME
					echo '        <desc lang="pt">'${!desc}'</desc>' >> $BASEPATH/$DUMMYFILENAME
					echo '    </programme>' >> $BASEPATH/$DUMMYFILENAME
			done
		done

		echo '</tv>' >> $BASEPATH/$DUMMYFILENAME
}

fixall () {
	for xml in $BASEPATH/*.xml; do
		echo "Fixing $xml ... "
		sleep 1
		## Structural Fixes
		sed -i "/<url>/d" "$xml"
		sed -i "s/lang=\"\"/lang=\"pt-BR\"/g" $xml
		## Language Fixes (Might Not be Necessary)
		sed -i "s/<display-name>/<display-name lang=\"pt-BR\">/g" $xml
		sed -i "s/lang=\"pt\"/lang=\"pt-BR\"/g" $xml

	done	
}



downloadepgs () {
	INDEX=1
	for list in ${LISTS[*]}; do
		sleep 1
		dir="$(TMPDIR=$PWD mktemp -d)" ## makes a temp dir so that we can download the file, rename it and keep it's extention.
		wget -q --show-progress -P $dir --content-disposition --trust-server-names ${list[*]}
		regex="\?"
		for file in $dir/*; do
			if [[ $file =~ $regex ]]; 
				then
					ext="xml"
				else
					echo "Not!"
					ext=${file##*.}
			fi
			echo  "Extention = " $ext " Will rename it to " $BASEPATH/$INDEX.$ext
			mv $file $BASEPATH/$INDEX.$ext
		done
		rmdir "$dir"
		let INDEX=${INDEX}+1
	done
}



extractgz () {
	echo "Extracting compressed files..."
	gunzip -f $BASEPATH/*.gz
	find . -type f  ! -name "*.*" -exec mv {} {}.xml \;
	sleep 2
	## workarround to fix unknown bug that causes the .xml extention not to be added to some files some times.
	INDEX=1
	for list in ${LISTS[*]}; do
		mv $BASEPATH/$INDEX $BASEPATH/$INDEX.xml
		let INDEX=${INDEX}+1
	done

}

sortall () {
	for xml in $BASEPATH/*.xml; do
		echo "Sorting $xml ..."
		sleep 1
		tv_sort --by-channel --output $xml $xml		
	done
}

mergeall () {
	fileslist=( $(ls $BASEPATH/*.xml) )
	
	# MERGE The First 2
	echo "Merging ${fileslist[0]} with ${fileslist[1]}"
	tv_merge -i ${fileslist[0]} -m ${fileslist[1]} -o $BASEPATH/merged.xmltv
	
	#Merge the Rest
	for i in $(seq 2 ${#fileslist[@]}); do
		if [ ! -z "${fileslist[$i]}" ]; then
			echo "Merging ${fileslist[$i]} ... "
		fi
		tv_merge -i $BASEPATH/merged.xmltv -m ${fileslist[$i]} -o $BASEPATH/merged.xmltv
	done
}


getall () {
dummycreator
downloadepgs
extractgz
}

getall

fixall

sortall

##Remove old file
rm -f $BASEPATH/merged.xmltv

## Merge All the xml files into merged.xmltv
mergeall

## Cleanup
echo "Cleaning Up..."
rm $BASEPATH/*.xml

echo "Done!"
sleep 3
