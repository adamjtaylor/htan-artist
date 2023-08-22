# nf-artist
nf-artist is a Nextflow pipeline to generate interactive multiplexed image explorations and thumbnails.

- Add CI testing in Github action using included test data in `data/` and samplesheet `data/test_samplesheet.csv`
- Move logic on if minerva story or miniature thumbnail are run out of samplesheet and into `params`

## Minerva
- ✅ ~~Ensure H&E images are rendered with a fixed legend~~
- Allow for custom descriptions to be provided in the samplesheet and added into the Minerva story
- Update to new version of Minerva with channel selection

## Miniature

- Split `make_miniature` into two processes, one to run the miniature script for multiplexed images and one (that can have lower resource requirements) that makes the brightfield thumbnail for H&E images with TiffSlide