#!/usr/bin/env nextflow

// Enable dsl2
nextflow.enable.dsl=2

if (params.input) { input = file(params.input) } else { exit 1, 'Input samplesheet not specified!' }

params.outdir = "outputs"
params.remove_bg = true
params.level = -1
params.miniature = true
params.minerva = false

heStory = 'https://gist.githubusercontent.com/adamjtaylor/3494d806563d71c34c3ab45d75794dde/raw/d72e922bc8be3298ebe8717ad2b95eef26e0837b/unscaled.story.json'
heScript = 'https://gist.githubusercontent.com/adamjtaylor/bbadf5aa4beef9aa1d1a50d76e2c5bec/raw/1f6e79ab94419e27988777343fa2c345a18c5b1b/fix_he_exhibit.py'
minerva_description_script = 'https://gist.githubusercontent.com/adamjtaylor/e51873a801fee39f1f1efa978e2b5e44/raw/c03d0e09ec58e4c391f5ce4ca4183abca790f2a2/inject_description.py'


workflow SAMPLESHEET_SPLIT {
    take:
    samplesheet
    main:
    Channel
        .fromPath(samplesheet)
        .splitCsv (header:true, sep:',' )
        // Make meta map from the samplesheet
        .map { 
            row -> 
            def meta = [:]
            meta.id = file(row.image).simpleName
            meta.he = row.he.toBoolean()
            meta.ome = row.image ==~ /.+\.ome\.tif{1,2}$/
            image = file(row.image)
            [meta, image]
        }
        .set {images }
        
    emit: 
    images
}

workflow CONVERT {
    take: images
    main:
    images
        .filter {
            it[0].ome == false
        }
        .set {bioformats}

    bioformats2ometiff( bioformats)

    images
      .filter {
        it[0].ome == true
      }    
      .mix (bioformats2ometiff.out)
      .set {converted}
    emit: converted
}

workflow MINERVA {
  take:
  converted
  
  main:
  autominerva_story(converted)
  render_pyramid(autominerva_story.out)
  
  emit:
  minerva = render_pyramid.out
}

workflow {
    SAMPLESHEET_SPLIT ( input )
    //SAMPLESHEET_SPLIT.out.images.view()
    CONVERT( SAMPLESHEET_SPLIT.out.images )
    if (params.minerva == true) {
      MINERVA( CONVERT.out.converted ) 
      }
    if (params.miniature == true) {
      make_miniature ( CONVERT.out.converted )
    }
}

process bioformats2ometiff {
  input:
      tuple val(meta), file(image) 
  output:
      tuple val(meta), file("${image.simpleName}.ome.tiff")
  stub:
  """
  touch raw_dir
  touch "${image.simpleName}.ome.tiff"
  """
  script:
  """
  bioformats2raw $image 'raw_dir'
  raw2ometiff 'raw_dir' "${image.simpleName}.ome.tiff"
  """
}

process autominerva_story {
  errorStrategy 'ignore'
  input:
      tuple val(meta), file(image) 
  output:
      tuple val(meta), file(image), file('story.json')
  publishDir "$params.outdir/$workflow.runName",
    saveAs: {filename -> "${meta.id}/$workflow.runName/story.json"}
  stub: 
  """
  touch story.json
  """
  script:
  if (meta.he) {
    """
    wget -O story.json $heStory
    """
  } else {
    """
    python3 /auto-minerva/story.py $image > 'story.json'
    """
  }
}

process render_pyramid {
  input:
      tuple val(meta), file(image), file (story)
  output:
      tuple val(meta), path('minerva')
  publishDir "$params.outdir/$workflow.runName",
    saveAs: {filename -> "${meta.id}/$workflow.runName/minerva"}
  stub:
  """
  mkdir minerva
  touch minerva/tile1.png
  touch minerva/author.json
  touch minerva/index.html
  """
  script:
    """
    python3  /minerva-author/src/save_exhibit_pyramid.py $image $story 'minerva'
    cp /index.html minerva
    """
}


process make_miniature {
  echo true
  label "process_medium"
  input:
      tuple val(meta), file(image) 
  output:
      tuple val(meta), file('data/miniature.png'), emit: thumbnail
  publishDir "$params.outdir/$workflow.runName",
    saveAs: {filename -> "${meta.id}/$workflow.runName/thumbnail.png"}
  stub:
  """
  mkdir data
  touch data/miniature.png
  """
  script:
  if ( meta.he){
    """
    mkdir data
    magick $image -resize 512x512 data/miniature.png
    """
  } else {
    """
    mkdir data
    python3 /miniature/docker/paint_miniature.py $image 'miniature.png' --remove_bg $params.remove_bg --level $params.level
    """
  }
}