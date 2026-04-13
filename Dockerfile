FROM alpine:3.21 AS builder

RUN apk add --no-cache \
    build-base nasm yasm pkgconf \
    x264-dev x264-libs \
    linux-headers

ARG FFMPEG_VERSION=7.1.1
RUN wget https://ffmpeg.org/releases/ffmpeg-${FFMPEG_VERSION}.tar.xz \
    && tar xf ffmpeg-${FFMPEG_VERSION}.tar.xz

WORKDIR /ffmpeg-${FFMPEG_VERSION}

RUN ./configure \
    --disable-everything \
    --disable-doc --disable-htmlpages --disable-manpages --disable-podpages --disable-txtpages \
    --disable-autodetect --disable-network \
    --disable-programs --enable-ffmpeg \
    --enable-gpl --enable-small \
    --enable-static --disable-shared \
    --enable-v4l2-m2m \
    --enable-protocol=file,pipe,rtp,rtsp,tcp,udp \
    --enable-demuxer=rtsp,rtp,sdp,h264,hevc,mov,matroska \
    --enable-muxer=mp4,segment,matroska,image2,mjpeg \
    --enable-decoder=h264,hevc,mjpeg,h264_v4l2m2m,hevc_v4l2m2m \
    --enable-encoder=libx264,mjpeg,png,h264_v4l2m2m \
    --enable-parser=h264,hevc,mjpeg \
    --enable-bsf=h264_mp4toannexb,hevc_mp4toannexb,extract_extradata \
    --enable-filter=null,scale \
    --enable-libx264 \
    --extra-cflags="-Os -static" \
    --extra-ldflags="-static" \
    && make -j$(nproc) \
    && strip ffmpeg

FROM scratch
COPY --from=builder /ffmpeg-*/ffmpeg /ffmpeg
ENTRYPOINT ["/ffmpeg"]
