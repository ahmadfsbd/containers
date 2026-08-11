# VEP 116 Singularity And Plugins

This folder contains:

- `singularity.def` for building the VEP 116 Singularity image
- `prepare_offline_bundle.sh` for downloading VEP 116 plugin code only

The Singularity image and plugins are handled separately. The plugin script
downloads plugin code only.

## Build Singularity Image

Build from the official Ensembl Docker image:

```bash
cd singularity/vep
singularity build vep_116.0.sif singularity.def
```

The definition file uses:

```text
ensemblorg/ensembl-vep:release_116.0
```

## Download Plugin Code

Run on an internet-connected machine:

```bash
cd singularity/vep
./prepare_offline_bundle.sh /path/to/vep116
```

This downloads all plugin code from the Ensembl `VEP_plugins` release 116
archive, plus LOFTEE GRCh38 plugin code. It does not create data-resource
folders.

```text
/path/to/vep116/
  Plugins/
    *.pm
    loftee_GRCh38/
      LoF.pm
  manifest/
    resources.yaml
    checksums.sha256
```

Upload VEP 116 plugins under the versioned bucket prefix:

```text
gs://qmul-production-library-red/helper-files-and-scripts/vep/116/Plugins/
```

Do not overwrite the existing shared/top-level plugin folder:

```text
gs://qmul-production-library-red/helper-files-and-scripts/vep/Plugins/
```
