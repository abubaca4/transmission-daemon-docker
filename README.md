# Transmission Daemon Docker

This repository provides an automatically updated, lightweight Docker image for the Transmission BitTorrent client.

## 🏷 Supported Tags

The following tags are available for use, allowing you to choose between stable releases, betas, or bleeding-edge development builds:
* `latest`: Represents the most recent stable release of Transmission.
* `latest-include-beta`: Represents the most recent release, prioritizing betas or pre-releases if they are newer than the stable version.
* `main`: Built directly from the upstream `main` branch of the Transmission repository.
* **Versioned Tags**: Specific release versions (e.g., `4.1.3`) are also automatically generated based on upstream releases.
**Image path example**: `ghcr.io/abubaca4/transmission-daemon-docker:latest-include-beta`

## 🚀 Usage Examples
The configuration relies on environment variables and volume mounts specific to this image. The internal volumes are `/config`, `/watch`, and `/download`. The container exposes port `9091` for the Web UI and `51413` (TCP/UDP) for peer connections.

## Docker Compose
```yaml
services:
  transmission:
    image: ghcr.io/abubaca4/transmission-daemon-docker:latest-include-beta
    container_name: transmission
    environment:
      - TRANSMISSION_WATCH_DIR=/watch #optional
      - TRANSMISSION_DOWNLOAD_DIR=/download #optional
      - USER= #optional, for WebUI authentication
      - PASS= #optional, for WebUI authentication
      - WHITELIST= #optional, allowed IP addresses
      - PEERPORT=51413 #optional
      - HOST_WHITELIST= #optional, for RPC host whitelist
      - UMASK= #optional
    volumes:
      - /path/to/transmission/data:/config
      - /path/to/downloads:/download #optional
      - /path/to/watch/folder:/watch #optional
    ports:
      - 9091:9091
      - 51413:51413
      - 51413:51413/udp
    restart: unless-stopped
```

## Docker CLI
```bash
docker run -d \
  --name=transmission \
  -e TRANSMISSION_WATCH_DIR=/watch `#optional` \
  -e TRANSMISSION_DOWNLOAD_DIR=/download `#optional` \
  -e USER= `#optional` \
  -e PASS= `#optional` \
  -e WHITELIST= `#optional` \
  -e PEERPORT=51413 `#optional` \
  -e HOST_WHITELIST= `#optional` \
  -e UMASK= `#optional` \
  -p 9091:9091 \
  -p 51413:51413 \
  -p 51413:51413/udp \
  -v /path/to/transmission/data:/config \
  -v /path/to/downloads:/download `#optional` \
  -v /path/to/watch/folder:/watch `#optional` \
  --restart unless-stopped \
  ghcr.io/abubaca4/transmission-daemon-docker:latest-include-beta
```

**Note on Environment Variables**: The startup script natively processes `TRANSMISSION_WATCH_DIR`, `TRANSMISSION_DOWNLOAD_DIR`, `USER`, `PASS`, `WHITELIST`, `PEERPORT`, `HOST_WHITELIST`, and `UMASK` to automatically apply your preferences at runtime. Settings adjustments using `HOST_WHITELIST` and `UMASK` dynamically modify the `settings.json` file using `jq`.

## 🔄 Image Updates & Build Frequency
This repository leverages GitHub Actions to ensure images remain secure and up to date.
* **Automated Checks**: An automated workflow checks for updates every hour.
* **Upstream Tracking**: The build system calculates a revision hash combining the upstream Transmission commit SHA and the local repository hash. If these change, a new build is triggered.
* **Routine Maintenance (7-Day Rule)**: Even if the Transmission source code hasn't changed, a forced build is triggered if the existing image is older than 7 days (604,800 seconds). This guarantees that the underlying Alpine base image and third-party libraries (like `openssl`, `libcurl`, etc.) receive the latest security patches.

## ⚖️ Comparison with Alternatives
This project was built to address specific limitations found in other popular Transmission Docker images.
* **vs.** `linuxserver/docker-transmission`: Instead of relying on the pre-compiled version available in the Alpine package repository, this image builds Transmission directly from its source code using CMake.
* **vs.** `Relativ-IT/TransmissionBT`: This repository serves as a vastly improved version of Relativ-IT's setup. Key improvements include:
  * **No Manual Versioning**: There is no longer a need to manually define or maintain the version matrix; the Python generation script fetches releases directly from the GitHub API.
  * **Native ENV Support**: Stronger and more flexible support for runtime environment variables.
  * **Persistent Directories**: The `watch-dir` and `download-dir` configurations are intelligently handled and are not forcefully overwritten during container startup.