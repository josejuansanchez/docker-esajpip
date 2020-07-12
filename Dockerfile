# Stage 1
FROM alpine:3.12 AS builder

LABEL title="esajpip" \
  author="José Juan Sánchez"

ENV DEBIAN_FRONTEND=noninteractive 
ENV SWHV_PORT_JPIP=8090
ENV SWHV_DIR_IMAGE=/root/esajpip/images
ENV SWHV_DIR_LOG=/root/esajpip/log

RUN apk update \
    && apk upgrade \
    && apk add g++ \
    && apk add cmake \
    && apk add libgsf \
    && apk add libgsf-dev \ 
    && apk add libc-dev \
    && apk add git \
    && apk add build-base gcc \
    # Workaround 1:
    # This is a workaround to solve an issue with xlocale.h due it is not present in glibc 2.26
    && ln -s /usr/include/locale.h /usr/include/xlocale.h \
    && cd / \
    && git clone https://github.com/Helioviewer-Project/esajpip-SWHV.git --depth 1 \
    # Workaround 2:
    # cmake_minimum_required command should be added at the top of the CMakeLists.txt file
    && sed -i '1s/^/cmake_minimum_required(VERSION 3.17)\n/' /esajpip-SWHV/CMakeLists.txt \
    # Workaround 3:
    # Is necessary to include this library to compile the source code
    && sed -i '1s/^/#include <fcntl.h>\n/' /esajpip-SWHV/esajpip/esajpip/src/app_info.cc \
    && mkdir build \
    && cd build \
    && cmake ../esajpip-SWHV/ -DCMAKE_INSTALL_PREFIX=$HOME/esajpip -DSWHV_PORT_JPIP=8090 -DSWHV_DIR_IMAGE=$HOME/esajpip/images -DSWHV_DIR_LOG=$HOME/esajpip/log \
    && make install \
    && mkdir $HOME/esajpip/images \
    && mkdir $HOME/esajpip/log
 

# Stage 2
FROM alpine:3.12

ENV DEBIAN_FRONTEND=noninteractive 
ENV SWHV_PORT_JPIP=8090
ENV SWHV_DIR_IMAGE=/root/esajpip/images
ENV SWHV_DIR_LOG=/root/esajpip/log

RUN apk update \
    && apk add --no-cache libgsf-dev

COPY --from=builder /root/ /root/

VOLUME /root/esajpip/images
VOLUME /root/esajpip/log

EXPOSE 8090

WORKDIR /root/esajpip/server/esajpip

CMD ["/bin/sh", "-c", "/root/esajpip/server/esajpip/esajpip"]