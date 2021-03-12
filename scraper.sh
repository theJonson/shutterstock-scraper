#!/bin/bash

# Before you start you'll need a Shutterstock API key, fill that in the KEY variable, also update the s3 bucket on line 87 to match your target

#create working folder
WORK=/tmp/shutterstock
if [ ! -d "$WORK" ]; then
  mkdir $WORK
fi

#Move to the WORK directory
cd $WORK

#Build date variables
echo "Building Dates"
TODAY=`date +%F`
TIME=`date +%T`

#Build start and end date variables
echo "Building Start and End"
START=date_updated_start=$TODAY\T00:00:01Z
END=date_updated_end=$TODAY\T$TIME\Z

#Set API KEY, you'll need to get one from https://www.shutterstock.com/developers
KEY="<INSERT APIKEY HERE>"
API_KEY="Authorization: Bearer $KEY"

#Remove old image_ids.txt
echo "Remove old image ids"
rm -f $WORK/image_ids.txt

#Gets all images uploaded between 2 dates
echo "Find images"

curl -s -X GET https://api.shutterstock.com/v2/editorial/images/updated -H "Accept: application/json" -G -H "$API_KEY" --data-urlencode "type=addition" --data-urlencode "country=GBR" --data-urlencode "supplier_code=SPT" --data-urlencode "$START" --data-urlencode "$END" | jq -r '.data[] | .id' > $WORK/image_ids.txt

#Check if there are any image ids
if [ -f $WORK/image_ids.txt ]
then
    if [ -s $WORK/image_ids.txt ]
    then
        echo "Image IDs found in image_ids.txt"
    else
        echo "No Image IDs found in image_ids.txt"
        exit 1
    fi
else
    echo "Couldn't find image_ids.txt"
    exit 1
fi

#For each ID listed in image_ids license the image and output the result to json file
echo "License the images"
while IFS= read -r line
do
  curl -s -X POST "https://api.shutterstock.com/v2/editorial/images/licenses" -H "accept: application/json" -H "Content-Type: application/json" -H "$API_KEY" -d "{\"editorial\":[{\"editorial_id\":\"$line\",\"license\":\"premier_editorial_comp\",\"metadata\":{\"purchase_order\":\"-\"}}],\"country\":\"GBR\"}" > $WORK/$line.json
done < $WORK/image_ids.txt

#Remove existing json file just in case
rm -f $WORK/combined.json

#Combine all the individual image json responses into a single one
jq '.' $WORK/*.json > $WORK/combined.json

#Remove existing url file just in case
rm -f $WORK/urls.txt

#Filter the combined json to just get the download urls into a txt file
cat $WORK/combined.json | jq -r '.data[] | .download.url' > $WORK/urls.txt

#Pass the urls to curl to download the file -J is needed to output the .jpg file, otherwise the file name is the request url
#The cd at the top is really only needed for this command as curl doesn't have a folder path switch
xargs -n 1 curl -s -O -J -L < $WORK/urls.txt

#Clean up all the json files as we don't need them anymore
rm -f $WORK/*.json

#Upload files to S3 bucket - setup s3cmd first
s3cmd sync $WORK/*.jpg s3://<target-bucket> --skip-existing --quiet

#Remove any downloaded jpgs and txt files
rm -f $WORK/*.jpg
rm -f $WORK/*.txt
