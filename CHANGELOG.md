# Change Log
All notable changes to the docker-bio-linux8-resolwe project will be documented
in this file.
This project adheres to [Semantic Versioning](http://semver.org/).

## Unreleased

### Added

- Script serving as container's entrypoint executable that enables
  dynamically setting user and group IDs of the user running in the container
  by passing them via environment variables.
- Documentation on using the image, including mounting a local directory inside
  the container and passing the host user's user and group IDs to the container
  via environment variables.
- gosu 1.9.
- scikit-learn 0.14.1.
- Bioconductor R packages:
  - pd.hugene.2.0.st
  - pd.mogene.2.0.st
  - pd.mogene.1.0.st.v1
  - moe430acdf
  - hgu133plus2cdf
  - mouse4302cdf
  - mogene10stv1cdf
  - mirna20cdf
  - hgu95av2cdf
  - hgu133acdf
  - hgu133a2cd
  - hthgu133acd

### Changed

- No longer set `WORKDIR` to `/home/biolinux/data`.
- Update Resolwe Runtime Utilities to 1.0.0.

### Removed

- Remove creation of `~/auxiliary_data` directory since it is no longer
  necessary.
- Remove creation of `~/data` and `~/upload` directories since they will get
  automatically created when volumes are mounted from the host.

## 0.2.0 - 2016-05-17

### Added

- Script that calculates the change in size between the base and the new Docker
  image
- JBrowse 1.12.0.
- BEDOPS 2.4.15.
- GenomeTools 1.5.3.
- tabix (currently, 0.2.6).
- bedtools (currently, 2.17.0).
- p7zip-full (currently, 9.20.1).
- bamliquidator 1.2.0-0ppa1~trusty.
- MACS2 2.1.1.20160309.
- ROSE2 1.0.2.
- R packages:
  - argparse
  - chemut
  - devtools
  - RNASeqT
- Bioconductor R packages:
  - Rsamtools
  - reshape2
  - seqinr
  - stringr
  - tidyr
- vcfutils.pl from samtools package.
- cutadapt 1.9.1.
- HISAT2 2.0.3-beta.

## 0.1.0 - 2016-02-04

- Initial release.
