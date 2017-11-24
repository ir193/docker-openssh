FROM ubuntu:16.04

RUN apt-get update && \
    apt-get -y --no-install-recommends install openssh-server 

RUN mkdir -p /var/run/sshd && \
    sed -i "s/UsePrivilegeSeparation.*/UsePrivilegeSeparation no/g" /etc/ssh/sshd_config && \
    sed -i "s/UsePAM.*/UsePAM no/g" /etc/ssh/sshd_config && \
    sed -i "s/PermitRootLogin.*/PermitRootLogin yes/g" /etc/ssh/sshd_config && \
    mkdir -p /root/.ssh && \
    chmod 700 /root/.ssh


ADD entrypoint.sh /root/.ssh/
ADD insecure_rsa /root/.ssh/
ADD insecure_rsa.pub /root/.ssh/
ADD stopsshd /usr/bin/

RUN chmod 600 /root/.ssh/insecure_rsa


RUN apt-get -y --no-install-recommends  install \
        mpich libmpich-dev  make g++ wget openssh-server && \
    echo 'Host *' > /root/.ssh/config && \
    echo 'StrictHostKeyChecking no' >> /root/.ssh/config && \
    echo 'LogLevel quiet' >> /root/.ssh/config && \
    chmod 600 /root/.ssh/config


ADD mpirun_docker /usr/bin
ADD copyresults /usr/bin
ADD example/ /example/

RUN make -C /example && \
    mv /example/mpi_helloworld /usr/bin/ && \
    rm -r /example

RUN apt-get update && \
    apt-get --no-install-recommends -y install \
      python libpapi-dev libpci-dev libpopt-dev uuid-dev python-dev perl texinfo && \
    apt-get autoremove --purge -y && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    wget --no-check-certificate https://github.com/lanl/conceptual/tarball/v1.5.1 -O - | tar xz && \
    mv lanl* /conceptual && \
    cd /conceptual && \
    CC=mpicc ./configure && \
    (make || true) && \
    make && \
    make install && \
    cd / && \
    rm -r /conceptual

ENV LD_LIBRARY_PATH=/usr/local/lib

ADD build_examples.sh /root/
RUN cd /root && ./build_examples.sh && \
    rm /root/build_examples.sh && ldconfig

WORKDIR /root


ENTRYPOINT ["mpirun_docker"]