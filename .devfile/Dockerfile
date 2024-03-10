FROM registry.redhat.io/devspaces/udi-rhel8:latest

RUN dnf install -y https://github.com/ibmruntimes/semeru17-binaries/releases/download/jdk-17.0.10%2B7_openj9-0.43.0/ibm-semeru-open-17-jdk-17.0.10.7_0.43.0-1.x86_64.rpm

RUN rm -rf ${HOME}/.java/current
RUN mkdir -p ${HOME}/.java/current
RUN ln -s /usr/lib/jvm/ibm-semeru-open-17-jdk/* ${HOME}/.java/current