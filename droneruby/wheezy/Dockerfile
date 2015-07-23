FROM quay.io/dennybaa/drone-busybee:wheezy

ENV RVM_VERSION stable
ENV RVM_RUBYVER ruby-2.2

# Get ruby rvm
RUN gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 && \
    curl -sSL https://get.rvm.io | bash -s -- $RVM_VERSION --ruby=$RVM_RUBYVER && \
    echo rvm_install_on_use_flag=1 > /root/.rvmrc && \
    echo "source /etc/profile.d/rvm.sh" >> /root/.profile

ENTRYPOINT ["/bin/bash", "-lc"]
