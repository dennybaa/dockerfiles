FROM quay.io/dennybaa/drone-busybee:precise

# install software to dockerunit
RUN echo -e "#!/bin/sh\nexit 101\n" > /usr/sbin/policy-rc.d && \
    DEBIAN_FRONTEND=noninteractive && apt-get -y update && \
    apt-get -y install gdebi-core sshpass cron
