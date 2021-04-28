FROM ubuntu:20.10 AS builder

RUN apt-get update && apt-get install -y ca-certificates \
  && echo 'deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ groovy main restricted universe multiverse' > /etc/apt/sources.list \
  && echo 'deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ groovy-updates main restricted universe multiverse' >> /etc/apt/sources.list \
  && echo 'deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ groovy-backports main restricted universe multiverse' >> /etc/apt/sources.list \
  && echo 'deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ groovy-security main restricted universe multiverse' >> /etc/apt/sources.list \
  && apt-get update \
  && apt-get install -y build-essential curl gzip \
  && mkdir -p /data/soft /data/beanstalkd \
  && curl -Lo /data/soft/beanstalkd-1.12.tar.gz \
    https://hub.fastgit.org/beanstalkd/beanstalkd/archive/v1.12.tar.gz \
  && tar -C /data/soft -zxf /data/soft/beanstalkd-1.12.tar.gz \
  && cd /data/soft/beanstalkd-1.12 \
  && LDFLAGS=-static make PREFIX=/usr install \
  && chown -R nobody:nogroup /data/beanstalkd \
  && curl -Lo /data/soft/beanstool_v0.2.0_linux_amd64.tar.gz \
    https://hub.fastgit.org/src-d/beanstool/releases/download/v0.2.0/beanstool_v0.2.0_linux_amd64.tar.gz \
  && tar -C /data/soft -zxf /data/soft/beanstool_v0.2.0_linux_amd64.tar.gz \
  && mv /data/soft/beanstool_v0.2.0_linux_amd64/beanstool /usr/bin/ \
  && cd / \
  && rm -rf /data/soft

FROM busybox AS prod

COPY --from=builder /usr/bin/beanstalkd /usr/bin/beanstalkd
COPY --from=builder /usr/bin/beanstool /usr/bin/beanstool

VOLUME [ "/data/beanstalkd" ]

RUN addgroup -g 1000 -S beanstalkd \
  && adduser -S -G beanstalkd -u 1000 beanstalkd \
  && chown -R beanstalkd:beanstalkd /data/beanstalkd

WORKDIR /data/beanstalkd

USER beanstalkd:beanstalkd

EXPOSE 11211

ENTRYPOINT [ "/usr/bin/beanstalkd", "-l", "0.0.0.0", "-p", "11300", "-b", "/data/beanstalkd" ]

