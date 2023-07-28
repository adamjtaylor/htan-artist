// Create channel for synapse config
if (params.synapse_config) {
    ch_synapse_config = file(params.synapse_config, checkIfExists: true)
} else {
    exit 1, 'Please provide a Synapse config file for download authentication!'
}

params.convert = true
params.outdir = 'test-outputs'
params.thumbnail_width = 512
params.thumbnail_quality = 85
params.remove_bg = true
params.level = -1
params.dimred = 'umap'
heStory = 'https://gist.githubusercontent.com/adamjtaylor/3494d806563d71c34c3ab45d75794dde/raw/d72e922bc8be3298ebe8717ad2b95eef26e0837b/unscaled.story.json'



workflow SYNAPSE {

    take:
    ids


    main:

    synapse_show (
        ids,
        ch_synapse_config
    )

    // Get metadata into channels
    synapse_show
        .out
        .metadata
        .map { it -> synapseShowToMap(it) }
        .set { ch_samples_meta }

    synapse_get (
        ch_samples_meta,
        ch_synapse_config
    )
        .set {synapse_out}

    emit: synapse_out

        
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

workflow THUMBNAIL {
  take:
  converted
  
  main:
  converted
    .branch {
        h_and_e: it[0].h_and_e == true
        multiplex: it[0].h_and_e == false
    }
    .set { type }

    make_miniature ( type.multiplex )
    make_thumbnail ( type.h_and_e)

    make_miniature
        .out
        .mix ( make_thumbnail.out )
        .set { thumbnails }

    emit: thumbnails

}

workflow MINERVA {
  take:
  converted
  
  main:

  autominerva_story(converted)
  render_pyramid(autominerva_story.out)
}


workflow {
    SYNAPSE ( Channel.from('syn27056837','syn24829433') )
    CONVERT ( SYNAPSE.out)
    THUMBNAIL ( CONVERT.out )
    MINERVA ( CONVERT.out )
}


def synapseShowToMap(synapse_file) {
        def meta = [:]
        def category = ''
        synapse_file.eachLine { line ->
            def entries = [null, null]
            if (!line.startsWith(' ') && !line.trim().isEmpty()) {
                category = line.tokenize(':')[0]
            } else {
                entries = line.trim().tokenize('=')
            }
            meta["${category}|${entries[0]}"] = entries[1]
        }
        meta.id = meta['properties|id']
        meta.name = meta['properties|name']
        meta.md5 = meta['File|md5']
        meta.ome = meta['properties|name'] ==~ /.+\.ome\.tif{1,2}$/
        meta.h_and_e =  meta['annotations|ImagingAssayType'] == "['H&E']"
        return meta.findAll{ it.value != null }
    }

process synapse_show {
    tag "$id"
    label 'process_low'

    conda "bioconda::synapseclient=2.6.0"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/synapseclient:2.6.0--pyh5e36f6f_0' :
        'quay.io/biocontainers/synapseclient:2.6.0--pyh5e36f6f_0' }"

    input:
    val id
    path config

    output:
    path "*.txt"       , emit: metadata

    script:
    def args  = task.ext.args  ?: ''
    def args2 = task.ext.args2 ?: ''
    """
    synapse \\
        -c $config \\
        show \\
        $args \\
        $id \\
        $args2 \\
        > ${id}.metadata.txt
    rm $config
    """
}

process synapse_get {
    tag "$meta.id"
    label 'process_low'
    label 'error_retry'

    conda "bioconda::synapseclient=2.6.0"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/synapseclient:2.6.0--pyh5e36f6f_0' :
        'quay.io/biocontainers/synapseclient:2.6.0--pyh5e36f6f_0' }"

    input:
    val meta
    path config

    output:
    tuple val(meta), path('*'), emit: image

    script:
    def args = task.ext.args ?: ''
    """
    synapse \\
        -c $config \\
        get \\
        $args \\
        $meta.id
    shopt -s nullglob
    for f in *\\ *; do mv "\${f}" "\${f// /_}"; done
    """
}

process bioformats2ometiff {
  label "process_medium"
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
  if ( meta.h_and_e){
  """
  bioformats2raw $image 'raw_dir' --series 0
  raw2ometiff 'raw_dir' "${image.simpleName}.ome.tiff" --rgb
  """
  } else {
  """
  bioformats2raw $image 'raw_dir'
  raw2ometiff 'raw_dir' "${image.simpleName}.ome.tiff"
  """
  }
}

process make_miniature {
  label "process_medium"
  input:
      tuple val(meta), file(image) 
  output:
      tuple val(meta), file('data/miniature.jpg')
  publishDir "$params.outdir/$workflow.runName",
    saveAs: {filename -> "${meta.id}/$workflow.runName/thumbnail.jpg"}
  stub:
  """
  mkdir data
  touch data/miniature.jpg
  """
  script:
    """
    mkdir data
    python3 /miniature/docker/paint_miniature.py \
      $image 'miniature.jpg' \
      --remove_bg $params.remove_bg \
      --level $params.level \
      --dimred $params.dimred
    """
}

process make_thumbnail {
  label "process_medium"
  errorStrategy 'ignore'
  input:
      tuple val(meta), file(image) 
  output:
      tuple val(meta), file('miniature.jpg')
  publishDir "$params.outdir/$workflow.runName",
    saveAs: {filename -> "${meta.id}/$workflow.runName/thumbnail.jpg"}
  stub:
  """
  touch miniature.jpg
  """
  script:
  """
  convert $image  \\
    -thumbnail '${params.thumbnail_width}x${params.thumbnail_width}>' \\
    -unsharp 0x.5 \\
    -scene 1 \\
    -quality $params.thumbnail_quality \\
    miniature.jpg
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
  if (meta.h_and_e) {
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