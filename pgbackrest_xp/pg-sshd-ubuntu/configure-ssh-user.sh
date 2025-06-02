#!/bin/bash

# Check for SSH_USERNAME and SSH_USERPASS being set, error out if not.
: ${SSH_USERNAME:?"Error: SSH_USERNAME environment variable is not set."}
: ${SSH_USERPASS:?"Error: SSH_USERPASS environment variable is not set."}
: ${SSHD_CONFIG_ADDITIONAL:=""}

SSH_USERHOME=${SSH_USERHOME}
if [ "$SSH_USERNAME" == "postgres" ]; then
    echo "The username is 'postgres', thus its homedir is '/var/lib/postgresql'."
    SSH_USERHOME=/var/lib/postgresql
fi

# Create the user with the provided username and set the password.
if id "$SSH_USERNAME" &>/dev/null; then
    echo "User $SSH_USERNAME already exists!"
else
    useradd -ms /bin/bash "$SSH_USERNAME"
    echo "$SSH_USERNAME:$SSH_USERPASS" | chpasswd
    echo "Created user $SSH_USERNAME with the provided password."
fi

# If the user is postgres, let's grant it to do `sudo`.
if [ "$SSH_USERNAME" == "postgres" ]; then
   usermod -aG sudo postgres
   echo "Granted $SSH_USERNAME user to run `sudo`."
fi

# Set the authorized keys from the AUTHORIZED_KEYS environment variable (if provided)
if [ -n "$AUTHORIZED_KEYS" ]; then
    mkdir -p ${SSH_USERHOME}/.ssh
    echo "$AUTHORIZED_KEYS" > ${SSH_USERHOME}/.ssh/authorized_keys
    echo "Initing .ssh ('${SSH_USERHOME}/.ssh') dir for user $SSH_USERNAME ..."
    chown -R $SSH_USERNAME:$SSH_USERNAME ${SSH_USERHOME}/.ssh
    chmod 700 ${SSH_USERHOME}/.ssh
    chmod 600 ${SSH_USERHOME}/.ssh/authorized_keys
    echo "Authorized keys set for user $SSH_USERNAME"
    # Disable password authentication if authorized keys are provided
    sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
fi

# Apply additional SSHD configuration if provided
if [ -n "$SSHD_CONFIG_ADDITIONAL" ]; then
    echo "$SSHD_CONFIG_ADDITIONAL" >> /etc/ssh/sshd_config
    echo "Additional SSHD configuration applied"
fi

# Apply additional SSHD configuration from a file if provided
if [ -n "$SSHD_CONFIG_FILE" ] && [ -f "$SSHD_CONFIG_FILE" ]; then
    cat "$SSHD_CONFIG_FILE" >> /etc/ssh/sshd_config
    echo "Additional SSHD configuration from file applied"
fi

# Start the SSH server
echo "Starting SSH server..."
exec /usr/sbin/sshd -D
