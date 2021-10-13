#!/usr/bin/env nextflow

params.outdir = '.'
params.all = false
params.minerva = false
params.miniature = false
params.metadata = false
params.he = false
params.errorStrategy = 'ignore'
params.input = 's3://htan-imaging-example-datasets/HTA9_1_BA_L_ROI04.ome.tif'
params.echo = false
params.keepBg = false
params.bucket = false
params.level = -1
params.bioformats2ometiff = true
params.contactsheet = false

heStory = 'https://gist.githubusercontent.com/adamjtaylor/3494d806563d71c34c3ab45d75794dde/raw/d72e922bc8be3298ebe8717ad2b95eef26e0837b/unscaled.story.json'

if(params.keepBg == false) { 
  remove_bg = true
} else {
  remove_bg = false
}

if(params.bucket == false){
  bucket = ""
} else {
  bucket = "$params.bucket/"
}

if (params.input =~ /.+\.csv$/) {
  Channel
      .from(file(params.input, checkIfExists: true))
      .splitCsv(header:false, sep:'', strip:true)
      .map { it[0] }
      .unique()
      .map { it -> file(it) }
      .into { input_ch_ome; view_ch }
} else {
    Channel
    .fromPath(params.input)
    .into {input_ch_ome; input_ch_notome; view_ch}
}

if (params.echo) { view_ch.view() }

input_ch_ome
  .branch {
      ome: it =~ /.+\.ome\.tif{1,2}$/ || params.bioformats2ometiff == false
      other: true
    }
    .set { input_groups }

input_groups.ome
  .map { file -> tuple(file.parent, file.simpleName, file) }
  .into {ome_ch; ome_view_ch}

if (params.echo) {  ome_view_ch.view { "$it is an ometiff" } }

input_groups.other
  .map { file -> tuple(file.parent, file.simpleName, file) }
  .into {bf_convert_ch; bf_view_ch}

if (params.echo) {  bf_view_ch.view { "$it is NOT an ometiff" } }

process make_ometiff{
  label "process_medium"
  errorStrategy params.errorStrategy
  echo params.echo
  input:
    set parent, name, file(input) from bf_convert_ch

  output:
    set parent, name, file("${name}.ome.tiff") into converted_ch
  stub:
  """
  touch raw_dir
  touch "${name}.ome.tiff"
  """
  script:
  """
  bioformats2raw $input 'raw_dir'
  raw2ometiff 'raw_dir' "${name}.ome.tiff"
  """
}

ome_ch
  .mix(converted_ch)
  .into { ome_story_ch; ome_miniature_ch; ome_metadata_ch; ome_contactsheet_ch }

process make_story{
  label "process_medium"
  errorStrategy params.errorStrategy
  publishDir "$params.outdir/$workflow.runName", saveAs: {filename -> "auto_minerva_story_jsons$bucket$parent${name}.story.json"}
  echo params.echo
  when:
    params.minerva == true || params.all == true
  input:
    set parent, name, file(ome) from ome_story_ch
  output:
    set parent, name, file('story.json'), file(ome) into ome_pyramid_ch
  stub:
  """
  touch story.json
  """
  script:
  if(params.he == true)
    """
    wget -O story.json $heStory
    """
  else
    """
    python3 /auto-minerva/story.py $ome > 'story.json'
    """
}

process render_pyramid{
  label "process_medium"
  errorStrategy params.errorStrategy
  publishDir "$params.outdir/$workflow.runName", saveAs: {filename -> "minerva_stories$bucket$parent$name/"}
  echo params.echo
   when:
    params.minerva == true || params.all == true
  input:
    set parent, name, file(story), file(ome) from ome_pyramid_ch
  output:
    file 'minerva'
  stub:
  """
  mkdir minerva
  touch minerva/index.html
  """
  script:
  """
  python3  /minerva-author/src/save_exhibit_pyramid.py $ome $story 'minerva'
  cp /index.html minerva
  """
}

process render_miniature{
  label "process_high"
  errorStrategy params.errorStrategy
  publishDir "$params.outdir/$workflow.runName", saveAs: {filename -> "thumbnails$bucket$parent${name}.png"}
  echo params.echo
  when:
    params.miniature == true || params.all == true
  input:
    set parent, name, file(ome) from ome_miniature_ch
  output:
    file 'data/miniature.png'
  stub:
  """
  mkdir data
  touch data/miniature.png
  """
  script:
  """
  mkdir data
  python3 /miniature/docker/paint_miniature.py $ome 'miniature.png' --remove_bg $remove_bg --level $params.level
  """
}

process get_metadata{
  label "process_low"
  publishDir "$params.outdir/$workflow.runName", saveAs: {filename -> "tifftags$bucket$parent${name}.json"}
  errorStrategy params.errorStrategy
  echo params.echo
  when:
    params.metadata == true || params.all == true
  input:
    set parent, name, file(ome) from ome_metadata_ch
  output:
    file "tifftags.json"
  stub:
  """
  touch tifftags.json
  """
  script:
  """
  python /image-header-validation/image-tags2json.py $ome > "tifftags.json"
  """

}

process get_contactsheet{
  label "process_low"
  publishDir "$params.outdir/$workflow.runName", saveAs: {filename -> "contactsheets$bucket$parent${name}.json"}
  errorStrategy params.errorStrategy
  echo params.echo
  when:
    params.contactsheet == true || params.all == true
  input:
    set parent, name, file(ome) from ome_contactsheet_ch
  output:
    file "contactsheet.png"
  stub:
  """
  touch contactsheet.png
  """
  script:
  """
  wget -O make_contactsheet.py https://raw.githubusercontent.com/adamjtaylor/contactsheet/main/make_contactsheet.py
  python make_contactsheet.py $ome --dpi 600 --level $params.level
  """

}
