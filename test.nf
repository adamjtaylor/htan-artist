#!/usr/bin/env nextflow

// Enable dsl2
nextflow.enable.dsl=2

params.input_csv = './data/test.csv'
params.input_path = false

process SYNAPSE_GET {
  label "process_low"
  echo params.echo
  input:
    val synid
  output:
    tuple val(synid), file('*')
  stub:
  """
  touch "test.tif"
  """
  script:
  """
  synapse -c ~/.synapseConfig get $synid
  """
}

Channel
    .fromPath(params.input_csv)
    .splitText()
    .set { input_csv }

//input_csv.view()

if (params.input_path != false) {
  Channel
    .fromPath(params.input_path)
    .set { input_path }
} else {
    Channel.empty().set{input_path}
}

//input_path.view()

Channel
  .empty()
  .mix(input_path)
  .mix(input_csv)
  .branch {
    syn: it =~ /^syn\d+$/
    other: true
  }
  .set { inputs }

inputs.other
  .map { it -> file(it) }
  .map { it -> tuple(it.simpleName, it)}
  .set {files}

// files.view()

workflow  {
    SYNAPSE_GET(inputs.syn)
    SYNAPSE_GET.out.view()
    files
      .mix(
        SYNAPSE_GET.out
      )
      .view()
}
