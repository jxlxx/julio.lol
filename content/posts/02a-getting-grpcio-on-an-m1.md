---
title: Installing grpcio on an Apple Silicon/M1 
date: "2022-04-14"
description: How to install grpcio on an M1.
tldr: You need some flags
draft: false
tags: ["grpc", "python", "apple-silicon"]
---


```bash
GRPC_BUILD_WITH_BORING_SSL_ASM="" \
GRPC_PYTHON_BUILD_SYSTEM_OPENSSL=true \
GRPC_PYTHON_BUILD_SYSTEM_ZLIB=true \
python3 -m pip install grpcio==1.36.1
```

https://github.com/grpc/grpc/issues/24677
