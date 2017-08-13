FROM debian:jessie

RUN apt-get update && apt-get -y --no-install-recommends install \
    apt-transport-https \
    bzip2 \
    ca-certificates \
    curl \
    expect \
    git \
    lsb-release \
    node
    openssl \
    sudo \
    unzip \
    vim \
  && rm -rf /var/lib/apt/lists/* \
  && chmod +x po-util.sh config-expect.sh \
  && ./config-expect.sh \
  && ./po-util.sh install /particle basic \
  && rm -rf /var/lib/apt/lists/*


WORKDIR /code
ADD po-util.sh config-expect.sh /code

VOLUME /code

CMD po