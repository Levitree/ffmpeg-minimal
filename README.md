# ffmpeg-minimal

Statically-linked ffmpeg binary stripped to H.264/H.265 + MP4/MKV muxing. ~5MB.

## What's included

- **Demuxers:** RTSP, RTP, SDP, H.264, HEVC, MOV, Matroska
- **Muxers:** MP4, segment, Matroska, image2, MJPEG
- **Decoders:** H.264, HEVC, MJPEG
- **Encoders:** libx264, MJPEG, PNG
- **Protocols:** file, pipe, RTP, RTSP, TCP, UDP
- **Filters:** null, scale
- **BSFs:** h264_mp4toannexb, hevc_mp4toannexb, extract_extradata

## Usage

Copy the static binary into another image:

```dockerfile
COPY --from=ghcr.io/levitree/ffmpeg-minimal:latest /ffmpeg /usr/local/bin/ffmpeg
```
