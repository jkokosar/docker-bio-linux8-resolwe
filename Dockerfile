# Copyright 2016 The docker-bio-linux8-resolwe authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Dockerfile to build a Resolwe-tailored version of Bio-Linux 8

FROM resolwe/bio-linux8

MAINTAINER Genialis <dev-team@genialis.com>

COPY docker-entrypoint.sh /

# XXX: Remove this step after updating resolwe-runtime-utils
COPY re-import.sh re-import.sh
# XXX: Remove this step after updating resolwe-runtime-utils
COPY curlprogress.py /usr/local/bin/

RUN export DEBIAN_FRONTEND=noninteractive && \

    echo "System information:" && \
    export NPROC=$(nproc) && \
    echo "  - $NPROC processing units available" && \
    echo "  - $(free -h | grep Mem | awk '{print $2}') of memory available" && \

    echo "Adding Bradner Lab's pipeline PPA..." && \
    sudo add-apt-repository -y ppa:bradner-computation/pipeline && \

    echo "Installing apt packages..." && \
    sudo apt-get update && \
    sudo apt-get -y install --no-install-recommends \
      bamliquidator=1.2.0-0ppa1~trusty \
      bedtools \
      p7zip-full \
      python-pip \
      r-cran-devtools \
      # r-cran-devtools requires a newer version of r-cran-memoise
      r-cran-memoise \
      # chemut requires a newer version of r-cran-stringi
      r-cran-stringi \
      tabix \
      # required for building matplotlib (deepTools requires a newer version of matplotlib)
      libfreetype6-dev \
      pypy \
      libgsl0-dev \
      && \

    echo "Installing gosu..." && \
    GOSU_VERSION=1.9 && \
    sudo wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture)" && \
    # check gosu authenticity using gnupg
    sudo wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture).asc" && \
    export GNUPGHOME="$(mktemp -d)" && \
    gpg --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 && \
    gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu && \
    sudo rm -r "$GNUPGHOME" /usr/local/bin/gosu.asc && \
    # make gosu executable
    sudo chmod +x /usr/local/bin/gosu && \
    sudo gosu nobody true && \

    echo "Enabling vcfutils.pl from samtools package..." && \
    sudo ln -s /usr/share/samtools/vcfutils.pl /usr/local/bin/vcfutils.pl && \

    echo "Enabling SortMeRNA package utils scripts..." && \
    sudo ln -s /usr/share/sortmerna/scripts/merge-paired-reads.sh /usr/local/bin/merge-paired-reads.sh && \
    sudo ln -s /usr/share/sortmerna/scripts/unmerge-paired-reads.sh /usr/local/bin/unmerge-paired-reads.sh && \

    echo "Installing resolwe-runtime-utils..." && \
    sudo pip install resolwe-runtime-utils==1.0.0 && \
    # XXX: Remove this hack after updating resolwe-runtime-utils
    echo 're-checkrc() { _re-checkrc $? "$@"; }' >> ~/.bash_profile && \
    # XXX: Remove this hack after updating resolwe-runtime-utils
    cat re-import.sh >> ~/.bash_profile && \
    rm re-import.sh && \
    # XXX: Remove this after updating resolwe-runtime-utils
    sudo chmod +x /usr/local/bin/curlprogress.py && \
    # TODO: Remove this after removing re-require from processes in resolwe-bio
    echo 're-require() { echo "WARNING: Using re-require is deprecated"; }' >> ~/.bash_profile && \
    # This is a convenience that makes 're-checkrc' and 're-import' functions
    # also available when starting the container with 'docker run -it'
    # XXX: Remove this after updating resolwe-runtime-utils
    echo "[[ -f ~/.bash_profile ]] && source ~/.bash_profile" >> ~/.bashrc && \

    echo "Installing MACS2..." && \
    sudo pip install MACS2==2.1.1.20160309 && \

    echo "Installing ROSE2..." && \
    sudo pip install rose2==1.0.2 && \

    echo "Installing cutadapt..." && \
    sudo pip install cutadapt==1.9.1 && \

    echo "Installing htseq..." && \
    sudo pip install htseq==0.6.1 && \

    echo "Installing pysam..." && \
    sudo pip install pysam==0.9.1.3 && \

    echo "Installing scikit-learn..." && \
    sudo pip install scikit-learn==0.17.1 && \

    echo "Installing xlrd..." && \
    sudo pip install xlrd==1.0.0 && \

    echo "Installing Orange..." && \
    sudo pip install orange==2.7.8 && \

    echo "Installing deepTools..." && \
    sudo pip install deeptools==2.3.1 && \

    echo "Installing biox..." && \
    sudo pip install hg+https://bitbucket.org/mstajdohar/biox@9bcf3b0#egg=biox && \
    sudo mv /usr/local/lib/python2.7/dist-packages/biox/config_example.py /usr/local/lib/python2.7/dist-packages/biox/config.py && \

    echo "Installing JBrowse..." && \
    JBROWSE_VERSION=1.12.0 && \
    JBROWSE_SHA1SUM=c74adeb9840ae5c9348e59a9054fa93cf68d0402 && \
    wget -q https://jbrowse.org/releases/JBrowse-$JBROWSE_VERSION.zip -O jbrowse.zip && \
    echo "$JBROWSE_SHA1SUM *jbrowse.zip" | sha1sum -c - && \
    unzip -q jbrowse.zip && \
    rm jbrowse.zip && \
    cd JBrowse-$JBROWSE_VERSION && \
    # patch setup.sh script to prevent formatting of example data and building
    # support for legacy tools
    sed -i '/Formatting Volvox example data .../,$d' setup.sh && \
    ./setup.sh && \
    # remove all files and directories except those we explicitly want to keep
    find . -depth -not \( \
        -path './bin*' -o \
        -path './src/perl5*' -o \
        -path './extlib/lib/perl5*' \
        -o \( -type d -not -empty \) \
    \) -delete && \
    echo "PATH=\$PATH:~/JBrowse-$JBROWSE_VERSION/bin" >> ~/.bash_profile && \
    cd .. && \

    echo "Installing BEDOPS..." && \
    BEDOPS_VERSION=2.4.15 && \
    BEDOPS_SHA1SUM=6e7ca9394f1805888cf7ccc73fbe76b25f089ad9 && \
    wget -q https://github.com/bedops/bedops/releases/download/v$BEDOPS_VERSION/bedops_linux_x86_64-v$BEDOPS_VERSION.tar.bz2 -O bedops.tar.bz2 && \
    echo "$BEDOPS_SHA1SUM *bedops.tar.bz2" | sha1sum -c - && \
    mkdir BEDOPS-$BEDOPS_VERSION && \
    tar -xf bedops.tar.bz2 --directory BEDOPS-$BEDOPS_VERSION && \
    rm bedops.tar.bz2 && \
    echo "PATH=\$PATH:~/BEDOPS-$BEDOPS_VERSION/bin" >> ~/.bash_profile && \

    echo "Installing GenomeTools..." && \
    GENOMETOOLS_VERSION=1.5.3 && \
    GENOMETOOLS_SHA1SUM=a0a3a18acf68728ffb177a54c81ddb3295aa325d && \
    wget -q https://github.com/genometools/genometools/archive/v$GENOMETOOLS_VERSION.tar.gz -O genometools.tar.gz && \
    echo "$GENOMETOOLS_SHA1SUM *genometools.tar.gz" | sha1sum -c - && \
    mkdir genometools-$GENOMETOOLS_VERSION && \
    tar -xf genometools.tar.gz --directory genometools-$GENOMETOOLS_VERSION --strip-components=1 && \
    rm genometools.tar.gz && \
    cd genometools-$GENOMETOOLS_VERSION && \
    make 64bit=yes cairo=no -j $NPROC && \
    sudo make 64bit=yes cairo=no install && \
    cd .. && \
    rm -rf genometools-$GENOMETOOLS_VERSION && \

    echo "Installing HISAT2..." && \
    HISAT_VERSION=2.0.3-beta && \
    HISAT_SHA1SUM=d7a06ddb4d263f47140871de3ddd6ae5fbbf9d14 && \
    wget -q ftp://ftp.ccb.jhu.edu/pub/infphilo/hisat2/downloads/hisat2-$HISAT_VERSION-Linux_x86_64.zip -O hisat2.zip && \
    echo "$HISAT_SHA1SUM *hisat2.zip" | sha1sum -c - && \
    unzip -q hisat2.zip && \
    rm hisat2.zip && \
    # remove debugging files, documentation and examples
    rm hisat2-$HISAT_VERSION/*-debug && \
    rm -r hisat2-$HISAT_VERSION/doc && \
    rm -r hisat2-$HISAT_VERSION/example && \
    echo "PATH=\$PATH:~/hisat2-$HISAT_VERSION" >> ~/.bash_profile && \

    echo "Installing STAR..." && \
    STAR_VERSION=2.5.2a && \
    STAR_SHA1SUM=65f3fb6aca880caac942dfa9285276fba71edf17 && \
    wget -q https://github.com/alexdobin/STAR/archive/$STAR_VERSION.tar.gz -O STAR.tar.gz && \
    echo "$STAR_SHA1SUM *STAR.tar.gz" | sha1sum -c - && \
    mkdir STAR-$STAR_VERSION && \
    tar -xf STAR.tar.gz --directory STAR-$STAR_VERSION --strip-components=1 && \
    rm STAR.tar.gz && \
    rm -r STAR-$STAR_VERSION/doc && \
    rm -r STAR-$STAR_VERSION/source && \
    rm -r STAR-$STAR_VERSION/extras && \
    rm -r STAR-$STAR_VERSION/bin/Linux_x86_64 && \
    rm -r STAR-$STAR_VERSION/bin/MacOSX_x86_64 && \
    echo "PATH=\$PATH:~/STAR-$STAR_VERSION/bin/Linux_x86_64_static" >> ~/.bash_profile && \

    echo "Installing kentUtils..." && \
    KU_VERSION=302.1.0 && \
    KU_SHA1SUM=810cec2881472090f8d92f1f07adf8703bcda5ae && \
    wget -q https://codeload.github.com/ENCODE-DCC/kentUtils/zip/v$KU_VERSION -O kentUtils.zip && \
    echo "$KU_SHA1SUM *kentUtils.zip" | sha1sum -c - && \
    unzip -q kentUtils.zip && \
    rm kentUtils.zip && \
    rm -r kentUtils-$KU_VERSION/src && \
    find kentUtils-$KU_VERSION/bin/linux.x86_64 -type f -not -name 'bedGraphToBigWig' -print0 | xargs -0 rm -- && \
    echo "PATH=\$PATH:~/kentUtils-$KU_VERSION/bin/linux.x86_64" >> ~/.bash_profile && \

    echo "Installing TransDecoder..." && \
    TD_VERSION=3.0.0 && \
    TD_SHA1SUM=6c798327cd41773b34b36152162623613a3fdda9 && \
    wget -q https://codeload.github.com/TransDecoder/TransDecoder/tar.gz/v$TD_VERSION -O TransDecoder.tar.gz && \
    echo "$TD_SHA1SUM *TransDecoder.tar.gz" | sha1sum -c - && \
    mkdir TransDecoder-$TD_VERSION && \
    tar -xf TransDecoder.tar.gz --directory TransDecoder-$TD_VERSION --strip-components=1 && \
    rm TransDecoder.tar.gz && \
    cd TransDecoder-$TD_VERSION && \
    make && \
    rm -r sample_data && \
    cd .. && \
    echo "PATH=\$PATH:~/TransDecoder-$TD_VERSION" >> ~/.bash_profile && \
    echo "PATH=\$PATH:~/TransDecoder-$TD_VERSION/util" >> ~/.bash_profile && \

    echo "Installing gotea..." && \
    GOTEA_VERSION=0.0.2 && \
    GOTEA_SHA1SUM=5dd7724bfb8d05be0238957ef719479804dca961 && \
    wget -q https://codeload.github.com/genialis/gotea/tar.gz/$GOTEA_VERSION -O gotea.tar.gz && \
    echo "$GOTEA_SHA1SUM *gotea.tar.gz" | sha1sum -c - && \
    mkdir gotea-$GOTEA_VERSION && \
    tar -xf gotea.tar.gz --directory gotea-$GOTEA_VERSION --strip-components=1 && \
    rm gotea.tar.gz && \
    cd gotea-$GOTEA_VERSION && \
    make && \
    cd .. && \
    echo "PATH=\$PATH:~/gotea-$GOTEA_VERSION" >> ~/.bash_profile && \

    echo "Installing ea-utils..." && \
    EA_UTILS_VERSION=1.1.2-537 && \
    EA_UTILS_SHA1SUM=688bddb1891ed186be0070d0d581816a35f7eb4e && \
    wget -q https://ea-utils.googlecode.com/files/ea-utils.${EA_UTILS_VERSION}.tar.gz -O ea-utils.tar.gz && \
    echo "$EA_UTILS_SHA1SUM *ea-utils.tar.gz" | sha1sum -c - && \
    mkdir ea-utils-$EA_UTILS_VERSION && \
    tar -xf ea-utils.tar.gz --directory ea-utils-$EA_UTILS_VERSION --strip-components=1 && \
    rm ea-utils.tar.gz && \
    cd ea-utils-$EA_UTILS_VERSION && \
    make && \
    cd .. && \
    echo "PATH=\$PATH:~/ea-utils-$EA_UTILS_VERSION" >> ~/.bash_profile && \

    echo "Installing Prinseq-LITE..." && \
    PRINSEQ_VERSION=0.20.4 && \
    PRINSEQ_SHA1SUM=b8560cdc059e9b4cbb1bab5142de29bde5d33f61 && \
    wget -q http://sourceforge.net/projects/prinseq/files/standalone/prinseq-lite-${PRINSEQ_VERSION}.tar.gz/download -O prinseq-lite.tar.gz && \
    echo "$PRINSEQ_SHA1SUM *prinseq-lite.tar.gz" | sha1sum -c - && \
    mkdir prinseq-lite-$PRINSEQ_VERSION && \
    tar -xf prinseq-lite.tar.gz --directory prinseq-lite-$PRINSEQ_VERSION --strip-components=1 && \
    rm prinseq-lite.tar.gz && \
    find prinseq-lite-0.20.4 -iname *.pl -type f | xargs chmod 0755 && \
    echo "PATH=\$PATH:~/prinseq-lite-$PRINSEQ_VERSION" >> ~/.bash_profile && \

    echo "Installing R packages..." && \
    sudo Rscript --slave --no-save --no-restore-history -e " \
      package_list = c( \
        'argparse' \
      ); \
      install.packages(package_list) \
    " && \

    echo "Installing Bioconductor R packages..." && \
    sudo Rscript --slave --no-save --no-restore-history -e " \
      package_list = c( \
        'DESeq2', \
        'rtracklayer', \
        'Rsamtools', \
        'reshape2', \
        'seqinr', \
        'stringr', \
        'tidyr', \
        'baySeq' \
      ); \
      source('http://www.bioconductor.org/biocLite.R'); \
      biocLite(package_list) \
    " && \

    echo "Installing R packages from GitHub..." && \
    sudo Rscript --slave --no-save --no-restore-history -e " \
      library(devtools); \
      install_github('jkokosar/chemut'); \
      install_github('jkokosar/RNASeqT') \
    " && \

    echo "Cleaning up..." && \
    sudo apt-get clean && \
    sudo rm -rf /var/lib/apt/lists/*

# XXX: Remove this after converting the whole Dockerfile to run as root
USER root

ENTRYPOINT ["/docker-entrypoint.sh"]

CMD ["/bin/bash"]
