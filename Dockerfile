FROM python:2.7.11
MAINTAINER Michael J. Stealey <mjstealey@gmail.com>

# Install debian system packages / prerequisites
RUN apt-get update && apt-get install -y \
    postgresql-9.4 \
    postgresql-client-9.4 \
    openssh-client \
    openssh-server

# Install pip packages
RUN pip install --upgrade pip
RUN pip install \
    mezzanine==4.1.0 \
    psycopg2==2.6.1 \
    gunicorn==19.4.5

# Upgrade mezzanine using source from Github
WORKDIR /usr/src
RUN git clone https://github.com/stephenmcd/mezzanine.git
WORKDIR /usr/src/mezzanine
RUN python setup.py install

# Install SSH for remote PyCharm debugging
RUN mkdir /var/run/sshd
RUN echo 'root:screencast' | chpasswd
RUN sed -i 's/PermitRootLogin without-password/PermitRootLogin yes/' /etc/ssh/sshd_config

# SSH login fix. Otherwise user is kicked off after login
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

ENV NOTVISIBLE "in users profile"
RUN echo "export VISIBLE=now" >> /etc/profile

# Add docker user for use with SSH debugging
RUN useradd -m docker \
    && echo 'docker:docker' | chpasswd

# Cleanup
RUN apt-get clean
RUN rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/src/mezzanine

# Set entry working directory 
WORKDIR /home/docker/pamweb

EXPOSE 22
CMD ["/usr/sbin/sshd", "-D"]
