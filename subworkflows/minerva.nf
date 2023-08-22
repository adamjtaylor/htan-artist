include { autominerva_story } from "../modules/autominerva_story.nf"
include { render_pyramid } from "../modules/render_pyramid.nf"

workflow MINERVA {
  take:
  converted
  
  main:

  // If H&E, used a fixed story from the assets dir
  converted
    .filter {
      it[0].minerva && it[0].he
    }
    .map { it -> [it[0], it[1], file( "$projectDir/assets/he_story.json", checkIfExists: true)] }
    .set { he_story }

  // If not H&E, run auto-minerva
  converted
    .filter {
      it[0].minerva && it[0].he == false
    } |
    autominerva_story |
  // Mix with the `he_story` channel and render the pyramid
      mix( he_story ) |
      render_pyramid
  
}
