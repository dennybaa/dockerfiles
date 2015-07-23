FROM buildpack-deps:trusty-scm

# Create busybee and .ssh for busybee and root
RUN BBSH=/home/busybee/.ssh && adduser --disabled-password --gecos "" busybee && \
    mkdir $BBSH && mkdir /root/.ssh && \
    chown busybee.busybee $BBSH && \
    chmod 700 $BBSH /root/.ssh

# Enable remote pubkey access
RUN BBSH=/home/busybee/.ssh && echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCdCmmPjsOBWRXc+PKdgDRrsciNjp25zTacyz8Gdkln2ma046brOYXAphhp/85DKgHtANBBt3cl4+HnpDbmAfyq2qZT7hWzAbMxtq0Sj+yyFyUdreXoe4gEKyxpV6o8p/R/XzEcawvqX/vFc5EIFmvTdamxZs9DQmOE5AZMzUB18Kerkrb0/arUcZ8iMi9Ng9a18avow+7oUFZ6Oub7ISz/dkIRojaKO/2paJZ4p+v7ZLn7Hq8TUeBkgAlx872oh8J8linhIq17zK6x4MGL8qiurp2hnfe0cuCxwcsYGy+4DfK51+E2vks6FprCIfF5hIdz26euPn67/YpM0F0b5nXF busybee@drone" >> $BBSH/authorized_keys && \
    chown busybee.busybee $BBSH/authorized_keys

# Create busybee credentials and make busybee pkey available for root
COPY id_rsa  /root/.ssh/busybee
COPY id_rsa* /home/busybee/.ssh/
RUN BBSH=/home/busybee/.ssh && \
    chmod 600 /root/.ssh/busybee $BBSH/id_rsa && \
    chown busybee.busybee $BBSH/id_rsa $BBSH/id_rsa

RUN DEBIAN_FRONTEND=noninteractive && apt-get -y update && \
    apt-get install -y openssh-server sudo && \
    mkdir /var/run/sshd && \
    echo "busybee ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/busybee && \
    chmod 440 /etc/sudoers.d/busybee
