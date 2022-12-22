# requires libtiff command line tools to be installed (tiffinfo/tiffset)
# this is only intended to be run on SVS files from Versa scanners which display as bright pink
# ideally this should be run before importing to OMERO

# the recommended pre-import workflow is:
#   1. Make sure Bio-Formats command line tools are available.
#      See https://docs.openmicroscopy.org/bio-formats/latest/users/comlinetools/index.html
#   2. Use "showinf -crop 0,0,512,512" on the SVS file to verify that it is bright pink.
#   3. Back up the SVS file.
#   4. Run this script to update the file in-place ("./svs-fix-colors.sh /path/to/file.svs").
#   5. Import the updated file to OMERO.
#   6. Verify that the image displays correctly in OMERO, and that macro and label images are correct.
#      When checking the imported slide, be sure to zoom all the way out and all the way in.

# Imported files can be converted in-place under the ManagedRepository if you wish. The main
# thumbnail will need to be deleted or force-recreated after fixing the SVS file.

# get the IFD (image) count
IFDS=`tiffinfo "$@" | grep "TIFF Directory" | wc -l`
echo "Processing $IFDS IFDs..."

# loop over each image to fix the color handling
let i=0
while [ $i -lt $(($IFDS)) ]
do
  # change the PhotometricInterpretation tag (262) to RGB (2) for every IFD
  tiffset -d $i -s 262 2 "$@"
  ((i++))
done
