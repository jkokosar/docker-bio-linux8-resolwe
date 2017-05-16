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

    echo "Installing apt packages..." && \
    sudo apt-get update && \
    sudo apt-get -y install --no-install-recommends \
      p7zip-full \
      python-pip \
      python3-pip \
      python3-dev \
      python3-numpy \
      python3-pandas \
      pypy \
      xml2 \
      libcurl3 \
      && \

    sudo apt-get -y remove samtools && \

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

    echo "Installing resolwe-runtime-utils..." && \
    sudo pip install resolwe-runtime-utils==1.1.0 && \
    sudo pip3 install resolwe-runtime-utils==1.1.0 && \
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

    echo "Installing samtools..." && \
    SAMTOOLS_VERSION=1.3.1 && \
    SAMTOOLS_SHA1SUM=abf80b2cf3264ed600e367b293ca2561aa25ec87 && \
    wget -q https://github.com/samtools/samtools/releases/download/$SAMTOOLS_VERSION/samtools-$SAMTOOLS_VERSION.tar.bz2 -O samtools.tar.bz2 && \
    echo "$SAMTOOLS_SHA1SUM *samtools.tar.bz2" | sha1sum -c - && \
    mkdir samtools-$SAMTOOLS_VERSION && \
    tar -xf samtools.tar.bz2 --directory samtools-$SAMTOOLS_VERSION --strip-components=1 && \
    rm samtools.tar.bz2 && \
    cd samtools-$SAMTOOLS_VERSION && \
    make && \
    sudo make install && \
    cd .. && \
    echo "PATH=\$PATH:~/samtools-$SAMTOOLS_VERSION" >> ~/.bash_profile && \

    echo "Installing bedtools..." && \
    BEDTOOLS_VERSION=2.26.0 && \
    BEDTOOLS_SHA1SUM=320c4e04bd0d1fac77a52022f449e5003bec9c3c && \
    wget -q https://github.com/arq5x/bedtools2/releases/download/v$BEDTOOLS_VERSION/bedtools-$BEDTOOLS_VERSION.tar.gz -O bedtools.tar.gz && \
    echo "$BEDTOOLS_SHA1SUM *bedtools.tar.gz" | sha1sum -c - && \
    mkdir bedtools-$BEDTOOLS_VERSION && \
    tar -zxvf bedtools.tar.gz --directory bedtools-$BEDTOOLS_VERSION --strip-components=1 && \
    rm bedtools.tar.gz && \
    cd bedtools-$BEDTOOLS_VERSION && \
    make && \
    cd .. && \
    echo "PATH=\$PATH:~/bedtools-$BEDTOOLS_VERSION/bin" >> ~/.bash_profile && \

    echo "Install iCount..." && \
    sudo pip3 install git+https://github.com/tomazc/iCount.git && \

    echo "Cleaning up..." && \
    sudo apt-get clean && \
    sudo rm -rf /var/lib/apt/lists/*

# XXX: Remove this after converting the whole Dockerfile to run as root
USER root

ENTRYPOINT ["/docker-entrypoint.sh"]
