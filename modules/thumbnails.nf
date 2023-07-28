process MINIATURE {
    label "process_high"
    
    publishDir "$params.outdir/$workflow.runName", 
        saveAs: "thumbnail.png"
    
    echo params.echo

    input:
        tuple val(synid), file(ome)
    
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


process RESIZE {
    label "process_high"
    
    publishDir "$params.outdir/$workflow.runName", 
        saveAs: "thumbnail.png"
    
    echo params.echo

    input:
        tuple val(synid), file(ome)
    
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
    magick $ome -resize 512x512 data/miniature.png
    """
}

