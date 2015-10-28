FROM quay.io/dennybaa/drone-busybee:trusty

ENV RBENV_VERSION 2.2.3

# Get rbenv and setup ~/.bashrc
RUN git clone --depth 1 https://github.com/sstephenson/rbenv.git ~/.rbenv && \
    git clone --depth 1 https://github.com/sstephenson/ruby-build.git ~/.rbenv/plugins/ruby-build && \
    echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc && \
    echo 'eval "$(rbenv init -)"' >> ~/.bashrc && \
    ~/.rbenv/bin/rbenv install $RBENV_VERSION

# Install default gems
RUN ~/.rbenv/bin/rbenv exec gem install bundler --no-ri --no-rdoc

CMD /bin/bash
