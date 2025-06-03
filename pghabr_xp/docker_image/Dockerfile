# Use an official Ubuntu base image
FROM ubuntu:24.04

# Set environment variables to avoid interactive prompts during installation
ENV DEBIAN_FRONTEND=noninteractive
ENV SSH_USERNAME="postgres"
ENV SSH_USERPASS="123"
ENV SSHD_CONFIG_ADDITIONAL=""

RUN apt update
RUN apt-get install curl ca-certificates -y
RUN install -d /usr/share/postgresql-common/pgdg
RUN curl -o /usr/share/postgresql-common/pgdg/apt.postgresql.org.asc --fail https://www.postgresql.org/media/keys/ACCC4CF8.asc
# Create the repository configuration file.
RUN sh -c "echo 'deb [signed-by=/usr/share/postgresql-common/pgdg/apt.postgresql.org.asc] https://apt.postgresql.org/pub/repos/apt noble-pgdg main' > /etc/apt/sources.list.d/pgdg.list"
# And update the package list.
RUN apt update

RUN apt-get update \
    && apt-get install -y iproute2 iputils-ping openssh-server sysstat postgresql-16 pgbackrest vim sudo telnet net-tools python3-pip python3-dev libpq-dev python3-venv \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    && mkdir -p /run/sshd \
    && chmod 755 /run/sshd \
    && if ! id -u "$SSH_USERNAME" > /dev/null 2>&1; then useradd -ms /bin/bash "$SSH_USERNAME"; fi \
    && echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config \
    && echo "PermitRootLogin no" >> /etc/ssh/sshd_config

# Copy the script to configure the user's password and authorized keys
COPY configure-ssh-user.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/configure-ssh-user.sh

# Expose SSH port
EXPOSE 22

# Start SSH server
CMD ["/usr/local/bin/configure-ssh-user.sh"]
