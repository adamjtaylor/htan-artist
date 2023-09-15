# HTAN Artist

A NextFlow pipeline to run image rendering process to generate resources for the [HTAN Portal](https://github.com/ncihtan/htan-portal).

- Converts bioformats files into OME-TIFF
- Sets thresholds for each channel and pepares 4-channel overlay groups using [Auto-Minerva](https://github.com/jmuhlich/auto-minerva)
- Renders a Minerva story using [Minerva Author](https://github.com/labsyspharm/minerva-author)
- Renders a thumbnail image using [Miniature](https://github.com/adamjtaylor/miniature)

A Docker container ([ghcr.io/sage-bionetworks-workflows/nf-artist](https://github.com/sage-bionetworks-workflows/nf-artist/pkgs/container/nf-artist)) is used to ensure reproducibility.

## Example usage

```
nextflow run Sage-Bionetworks-Workflows/nf-artist --input <path-to-samplesheet> --outdir <output-directory>
```


## Output

`nf-artist` outputs the following directory structure into the specified output directory (`outdir`):

```
├── outdir
│   ├── <simpleName or id for first row of samplesheet>
│   │   ├── thumbnail.jpeg
│   │   ├── minerva
│   │   │   ├── index.html
│   │   │   ├── exhibit.json
│   │   │   ├── story.json
│   │   │   ├── Group-1
│   │   │   │   ├── tile1.jpeg
│   │   │   │   ├── ...
│   │   │   ├── Group-<n>
│   │   │   │   ├── tile1.jpeg
│   │   │   │   ├── ...
│   ├── < simpleName or id for n'th row of samplesheet>
```

## Options

#### Input/Output Options:

* **input**: Path to a CSV sample sheet. This parameter is required. (Type: String)

* **outdir**: Specifies the directory where the output data should be saved. Default is "outputs". (Type: String)

#### Miniature Options:

* **remove_bg**: Setting this to true will remove the non-tissue background. Default is true. (Type: Boolean)

* **level**: Specifies the pyramid level used in thumbnails. Default is -1 (smallest). (Type: Integer)

* **dimred**: The dimensionality reduction method used. Default is "umap". Options include "umap", "tsne", and "pca". (Type: String)

* **colormap**: Specifies the colormap used. Ensure the colormap is compatible with the number of `n_components` selected. Default is "UCIE". 3D colormap options: "UCIE", "LAB", "RGB". 2D colormap options: "BREMM", "SCHUMANN", "STEIGER", "TEULING2", "ZIEGLER", "CUBEDIAGONAL". (Type: String)

* **n_components**: Specifies the number of components. Default is 3. Options are 2 and 3. (Type: Integer)

#### Samplesheet requirements

The samplesheet specified in the `input` parameter should be a CSV file with the following columns

- `image`: [string] Path or URI to image to be processed
- `convert`: [boolean] Should the image be converted to a OME-TIFF
- `he`: [boolean] Is the image a H&E image
- `minerva`: [boolean] Should a Minerva story be generated
- `miniature`: [boolean] Should a Miniature thumbnail be generated
- `id`: *optional* [string] A custom identifier to replace image simpleName in output directory structure 

