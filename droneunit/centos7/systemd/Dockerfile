FROM quay.io/dennybaa/droneunit:centos7
MAINTAINER "Denis Barishev" <dennybaa@gmail.com>
# wasn't able to create jessie systemd image so far!!!
#

ENV container docker

RUN yum -y update; \
    yum -y install systemd; yum clean all;

RUN cd /lib/systemd/system/sysinit.target.wants/; ls -1 | grep -v systemd-tmpfiles-setup.service | xargs rm; \
    rm -f /lib/systemd/system/multi-user.target.wants/*;\
    rm -f /etc/systemd/system/*.wants/*;\
    rm -f /lib/systemd/system/local-fs.target.wants/*; \
    rm -f /lib/systemd/system/sockets.target.wants/*udev*; \
    rm -f /lib/systemd/system/sockets.target.wants/*initctl*; \
    rm -f /lib/systemd/system/basic.target.wants/*;\
    rm -f /lib/systemd/system/anaconda.target.wants/*;\
    systemctl preset sshd;

# we can have ssh
EXPOSE 22

VOLUME [ "/sys/fs/cgroup" ]
CMD [ "/usr/sbin/init" ]
