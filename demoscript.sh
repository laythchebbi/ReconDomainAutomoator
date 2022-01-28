#!/bin/bash

if [ $# -gt 2 ]; then
	echo "Usage: ./demoscript.sh domain"
	echo "Example: ./demoscript.sh google.com"
	exit 1
fi
if [ ! -d "thridlevels" ]; then
	mkdir thirdlevels
fi
if [ ! -d "scans" ]; then
	mkdir scans
fi

pwd=$(pwd)
echo "Gathering domains with sublist3r..."
sublist3r -d $1 -o final.txt
echo $1 >> final.txt

echo "Compling third level domains"
cat final.txt | grep -Po "(\w+\.\w+\.\w+)$" | sort -u >> third-level.txt

echo "Gathering full third lelvel domains with sublist3r"
for domain in $(cat third-level.txt);
do
       	sublist3r -d $domain -o $domain.txt; 
	cat $domain.txt | sort -u  >> final.txt;
	done
if [ $# -eq 2 ];
then
       echo "Probing for live third-level domains"
       cat final.txt | sort -u | grep -v $2 | httprobe -s -p https:443 | sed 's/https\?:\/\///' | tr -d ":443" > probed.txt
else
	echo "Probling for live third-level domains"
	cat final.txt | sort -u | httprobe -s -p https:443 | sed 's/https\?:\/\///'| tr -d ":443" > probed.txt

fi
echo "Scanning for open ports..."
nmap -iL probed.txt -T5 -oA scans/scanned.txt
echo "Running eyewitness..."
eyewitness -f $pwd/probed.txt -d $1 --web