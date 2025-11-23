# 署名に必要な最低限：bash, openssl, ca-certificates, coreutils, grep
FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      bash openssl ca-certificates coreutils findutils grep sed less \
 && rm -rf /var/lib/apt/lists/*

# ローカルタイムゾーンが必要なら（TZ 環境変数を使用）
RUN ln -fs /usr/share/zoneinfo/Asia/Tokyo /etc/localtime && dpkg-reconfigure -f noninteractive tzdata

WORKDIR /work
