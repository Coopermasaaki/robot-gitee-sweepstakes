FROM openeuler/openeuler:23.03 as BUILDER
RUN dnf update -y && \
    dnf install -y golang && \
    go env -w GOPROXY=https://goproxy.cn,direct

MAINTAINER zengchen1024<chenzeng765@gmail.com>

# build binary
WORKDIR /go/src/github.com/opensourceways/robot-gitee-sweepstakes
COPY . .
RUN GO111MODULE=on CGO_ENABLED=0 go build -a -o robot-gitee-sweepstakes -buildmode=pie --ldflags "-s -linkmode 'external' -extldflags '-Wl,-z,now'" .

# copy binary config and utils
FROM openeuler/openeuler:22.03
RUN dnf -y update && \
    dnf in -y shadow && \
    dnf remove -y gdb-gdbserver && \
    groupadd -g 1000 sweepstakes && \
    useradd -u 1000 -g sweepstakes -s /sbin/nologin -m sweepstakes && \
    echo > /etc/issue && echo > /etc/issue.net && echo > /etc/motd && \
    mkdir /home/sweepstakes -p && \
    chmod 700 /home/sweepstakes && \
    chown sweepstakes:sweepstakes /home/sweepstakes && \
    echo 'set +o history' >> /root/.bashrc && \
    sed -i 's/^PASS_MAX_DAYS.*/PASS_MAX_DAYS   90/' /etc/login.defs && \
    rm -rf /tmp/*

USER sweepstakes

WORKDIR /opt/app

COPY  --chown=sweepstakes --from=BUILDER /go/src/github.com/opensourceways/robot-gitee-sweepstakes/robot-gitee-sweepstakes /opt/app/robot-gitee-sweepstakes

RUN chmod 550 /opt/app/robot-gitee-sweepstakes && \
    echo "umask 027" >> /home/sweepstakes/.bashrc && \
    echo 'set +o history' >> /home/sweepstakes/.bashrc

ENTRYPOINT ["/opt/app/robot-gitee-sweepstakes"]
