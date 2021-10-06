#!/bin/bash
ome=$(tiffcomment !{ome})
sizec_str=$(echo $ome | grep -oE "SizeC=.(\d+).")
sizec_num=$(echo $sizec_str | grep -oE "\d+")
echo "SizeC: $sizec_num"

planes_str=$(echo $ome | grep -oE "PlaneCount=.(\d+)." )
planes_num=$(echo $planes_str | grep -oE "\d+")
echo "planes: $planes_num"


echo "Updating PlaneCount to match SizeC"
planes_str_new=${sizec_str/SizeC/PlaneCount}
echo "New plane string: $planes_str_new"

echo "Writing replacement XML"
echo "${ome/$planes_str/$planes_str_new}" > new.ome.xml

echo "Injecting replacement XML"
tiffcomment -set 'new.ome.xml' !{ome}

echo "Complete!"
