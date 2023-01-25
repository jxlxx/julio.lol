---
title: Running the Confluent Python Client for Kafka on Apple Silicon/M1 
date: "2022-04-14"
description: How to install confluent-kafka on an M1.
draft: false
tldr: You need to build `librdkafka` locally, and then install `confluent-kafka` with some flags specifying where to look for the `librdkafka` dylibs.
tags: ["kafka", "python", "apple-silicon"]
---

# `Librdkafka`

`confluent-kafka` requires `librdkafka`. `brew install librdkafka` didn't work for me, so I needed to clone the repo and build it. This looks a little convoluted but I simply don't feel like investigating and making it cleaner.


Clone the repo and and install the `librdkafka` dependencies:

```bash
git clone https://github.com/edenhill/librdkafka.git
cd librdkafka
./configure --install-deps
```

Then you need install some more dependecies and do some special things for `openssl`:    

```bash
brew install openssl zstd pkg-config
brew link openssl --force
export PATH="/opt/homebrew/opt/openssl@3/bin:$PATH" 
```

💡 **Note:** I used the `/opt/homebrew/opt` path but maybe `/opt/homebrew/Cellar` makes more sense? But either way it works

And then a bit more configuration:

```bash
./configure
make
sudo make install
```


# `confluent-kafka`

Now you can install with python, but you need to specify the location of the `librdkafka` libs like so:

```bash
python -m pip install --global-option=build_ext --global-option="-I/usr/local/include" \
                      --global-option="-L/usr/local/lib" confluent-kafka

```       

References:
https://github.com/confluentinc/confluent-kafka-python/issues/1190
