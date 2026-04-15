FROM alpine:3.21 AS builder

RUN apk add --no-cache \
    build-base nasm yasm pkgconf cmake meson samurai git wget \
    linux-headers bash diffutils perl \
    zlib-dev zlib-static \
    x264-dev x264-libs

WORKDIR /src

# --- dav1d (AV1 decoder, NEON-optimized for ARM64) ---
ARG DAV1D_VERSION=1.5.1
RUN wget -q https://code.videolan.org/videolan/dav1d/-/archive/${DAV1D_VERSION}/dav1d-${DAV1D_VERSION}.tar.gz \
    && tar xf dav1d-${DAV1D_VERSION}.tar.gz \
    && cd dav1d-${DAV1D_VERSION} \
    && meson setup build \
       --prefix=/usr/local --libdir=lib --buildtype=release \
       --default-library=static -Denable_tools=false -Denable_tests=false \
    && ninja -C build install

# --- SVT-AV1 (AV1 encoder, realtime) ---
ARG SVTAV1_VERSION=2.3.0
RUN wget -q https://gitlab.com/AOMediaCodec/SVT-AV1/-/archive/v${SVTAV1_VERSION}/SVT-AV1-v${SVTAV1_VERSION}.tar.gz \
    && tar xf SVT-AV1-v${SVTAV1_VERSION}.tar.gz \
    && cd SVT-AV1-v${SVTAV1_VERSION} \
    && cmake -S . -B build -GNinja \
       -DCMAKE_INSTALL_PREFIX=/usr/local -DCMAKE_INSTALL_LIBDIR=lib \
       -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=OFF \
       -DBUILD_APPS=OFF -DBUILD_DEC=OFF \
    && ninja -C build install

# --- libvpx (VP8 + VP9) ---
ARG LIBVPX_VERSION=1.15.0
RUN wget -q https://github.com/webmproject/libvpx/archive/refs/tags/v${LIBVPX_VERSION}.tar.gz -O libvpx.tar.gz \
    && tar xf libvpx.tar.gz \
    && cd libvpx-${LIBVPX_VERSION} \
    && ./configure --prefix=/usr/local \
       --enable-static --disable-shared --disable-examples --disable-tools \
       --disable-docs --disable-unit-tests --enable-vp8 --enable-vp9 --enable-pic \
    && make -j$(nproc) install

# --- x265 (HEVC encoder) ---
ARG X265_VERSION=4.1
RUN wget -q https://bitbucket.org/multicoreware/x265_git/downloads/x265_${X265_VERSION}.tar.gz \
    && tar xf x265_${X265_VERSION}.tar.gz \
    && cd x265_${X265_VERSION}/build/linux \
    && cmake -G Ninja ../../source \
       -DCMAKE_INSTALL_PREFIX=/usr/local -DCMAKE_INSTALL_LIBDIR=lib \
       -DCMAKE_BUILD_TYPE=Release -DENABLE_SHARED=OFF -DENABLE_CLI=OFF \
    && ninja install \
    && X265_BUILD=$(awk '/#define X265_BUILD/ {print $3}' /usr/local/include/x265_config.h) \
    && sed -i -e "s/^Version: *$/Version: ${X265_BUILD}/" \
              -e "s/-lgcc_s//g" /usr/local/lib/pkgconfig/x265.pc

# --- ffmpeg ---
ARG FFMPEG_VERSION=7.1.1
RUN wget -q https://ffmpeg.org/releases/ffmpeg-${FFMPEG_VERSION}.tar.xz \
    && tar xf ffmpeg-${FFMPEG_VERSION}.tar.xz

WORKDIR /src/ffmpeg-${FFMPEG_VERSION}

RUN ./configure \
    --disable-everything \
    --disable-doc --disable-htmlpages --disable-manpages --disable-podpages --disable-txtpages \
    --disable-autodetect \
    --disable-programs --enable-ffmpeg \
    --enable-gpl --enable-version3 --enable-small \
    --enable-static --disable-shared \
    --enable-v4l2-m2m \
    --enable-protocol=file,pipe,rtp,rtsp,tcp,udp \
    --enable-demuxer=rtsp,rtp,sdp,h264,hevc,mov,matroska,webm_dash_manifest,ivf,ogg \
    --enable-muxer=mp4,segment,matroska,webm,image2,mjpeg,ivf,rtp \
    --enable-decoder=h264,hevc,mjpeg,vp8,vp9,av1,libdav1d,libvpx_vp8,libvpx_vp9,h264_v4l2m2m,hevc_v4l2m2m \
    --enable-encoder=libx264,libx265,libvpx_vp8,libvpx_vp9,libsvtav1,mjpeg,png,h264_v4l2m2m \
    --enable-parser=h264,hevc,mjpeg,vp8,vp9,av1 \
    --enable-bsf=h264_mp4toannexb,hevc_mp4toannexb,vp9_superframe,vp9_metadata,av1_metadata,extract_extradata,dump_extra \
    --enable-filter=null,scale,format,copy,fps \
    --enable-libx264 \
    --enable-libx265 \
    --enable-libvpx \
    --enable-libdav1d \
    --enable-libsvtav1 \
    --enable-zlib \
    --pkg-config-flags="--static" \
    --extra-cflags="-Os -static -I/usr/local/include" \
    --extra-ldflags="-static -L/usr/local/lib" \
    && make -j$(nproc) \
    && strip ffmpeg

FROM scratch
COPY --from=builder /src/ffmpeg-*/ffmpeg /ffmpeg
ENTRYPOINT ["/ffmpeg"]
