#!/bin/bash
echo "Reading file: $1"
cp $1 "$PWD/fixed.ome.tiff"
echo "Extracting tiffcomment"
xml=$(tiffcomment "$PWD/fixed.ome.tiff")
echo "$xml"

echo "Extracting SizeC"
sizec_str=$(echo "$xml" | grep -o 'SizeC="[0-9]\+"')
echo "$sizec_str"

planes_str=$(echo $xml | grep -o 'PlaneCount="[0-9]\+"')
echo "$planes_str"

echo "Updating PlaneCount to match SizeC"
planes_str_new=${sizec_str/SizeC/PlaneCount}
echo "New plane string: $planes_str_new"

echo "Writing replacement XML"
echo "${xml/$planes_str/$planes_str_new}"
echo "${xml/$planes_str/$planes_str_new}" > new.ome.xml

echo "Injecting replacement XML"
tiffcomment -set 'new.ome.xml' "$PWD/fixed.ome.tiff"

echo "Complete!"
