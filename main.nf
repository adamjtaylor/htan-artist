#!/usr/bin/env nextflow

// Enable dsl2
nextflow.enable.dsl=2


// Params
params.outdir = '.'
params.all = false
params.minerva = false
params.miniature = false
params.metadata = false
params.he = false
params.input_csv = false
params.input_synid = false
params.input_path = false
params.watch_path = false
params.watch_csv = false
params.echo = false
params.keepBg = false
params.level = -1
params.bioformats2ometiff = true
params.synapseconfig = '.synapseConfig'
params.watch_file = false

// Fetch scripts - BAKE THESE INTO THE DOCKER CONTAINER
heStory = 'https://gist.githubusercontent.com/adamjtaylor/3494d806563d71c34c3ab45d75794dde/raw/d72e922bc8be3298ebe8717ad2b95eef26e0837b/unscaled.story.json'
heScript = 'https://gist.githubusercontent.com/adamjtaylor/bbadf5aa4beef9aa1d1a50d76e2c5bec/raw/1f6e79ab94419e27988777343fa2c345a18c5b1b/fix_he_exhibit.py'
minerva_description_script = 'https://gist.githubusercontent.com/adamjtaylor/e51873a801fee39f1f1efa978e2b5e44/raw/c03d0e09ec58e4c391f5ce4ca4183abca790f2a2/inject_description.py'


// INPUT
if (params.synapseconfig != false){
  synapseconfig = file(params.synapseconfig)
}

print synapseconfig

if(params.keepBg == false) { 
  remove_bg = true
} else {
  remove_bg = false
}


// Workflow
include { SYNAPSE_GET } from './modules/synapse'
//include { RESIZE; MINIATUR } from './modules/minerva'
//include { STORY; RENDER } from './modules/minerva'


// INPUT WORKFLOW
workflow get_images {
  if (params.input_csv != false) {
    Channel
      .fromPath(params.input_csv)
      .splitText()
      .set { input_csv }
  } else {
    Channel.empty().set{input_csv}
  }

  if (params.input_path != false) {
    Channel
      .fromPath(params.input_path)
      .set { input_path }
  } else {
      Channel.empty().set{input_path}
  }

  Channel
    .empty()
    .mix(input_path)
    .mix(input_csv)
    .branch {
      syn: it =~ /^syn\d+$/
      paths: true
    }
    .set { inputs }

    inputs.syn.view()
    inputs.paths.view()

    SYNAPSE_GET(inputs.syn)
    
    inputs.paths
      .map { it -> file(it) }
      .map { it -> tuple(it.simpleName, it)}
      .mix(
        SYNAPSE_GET.out
      )
      .set { images }

    emit: images
}


//workflow minerva {

//  if (params.he = True) {
//    RENDER_HE( ome_pyramid_ch )
//  } else {
//    STORY( ome_pyramid_ch )
//    RENDER( STORY.out)
//  }
//
//}

//workflow thumbnail {
 // if params.he = True {
  //  RESIZE (ome_pyramid_ch)
  //} else {
  //  MINIATURE( ome_pyramid_ch )
 // }/
//}


workflow {
  get_images()
}