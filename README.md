# ffmpeg-minimal

Statically-linked ffmpeg binary tuned for Raspberry Pi 5 (VideoCore VII) with H.264/HEVC/VP8/VP9/AV1 support.

## What's included

- **Demuxers:** RTSP, RTP, SDP, H.264, HEVC, MOV, Matroska/WebM, IVF, Ogg
- **Muxers:** MP4, segment, Matroska, WebM, image2, MJPEG, IVF, RTP
- **Decoders:** H.264, HEVC, MJPEG, VP8, VP9, AV1 (native + libdav1d), libvpx VP8/VP9, `h264_v4l2m2m`, `hevc_v4l2m2m`
- **Encoders:** libx264, libx265, libvpx (VP8/VP9), libsvtav1, MJPEG, PNG, `h264_v4l2m2m`
- **Protocols:** file, pipe, RTP, RTSP, TCP, UDP
- **Filters:** null, scale, format, copy, fps
- **BSFs:** h264_mp4toannexb, hevc_mp4toannexb, vp9_superframe, vp9_metadata, av1_metadata, extract_extradata, dump_extra

## Pi 5 codec strategy

| Codec | Decode | Encode |
|-------|--------|--------|
| H.264 | `h264_v4l2m2m` (HW) / software | `libx264` / `h264_v4l2m2m` |
| HEVC  | `hevc_v4l2m2m` (HW, VideoCore VII) | `libx265` (software — no HW encode on Pi 5) |
| VP8   | `libvpx` | `libvpx` |
| VP9   | `libvpx-vp9` | `libvpx-vp9` |
| AV1   | `libdav1d` (NEON-optimized, fastest on ARM64) | `libsvtav1` (fastest realtime) |

## Usage

Copy the static binary into another image:

```dockerfile
COPY --from=ghcr.io/levitree/ffmpeg-minimal:latest /ffmpeg /usr/local/bin/ffmpeg
```
