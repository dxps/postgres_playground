# Ubuntu with OpenSSH server and PostgreSQL Server

This Docker image provides an Ubuntu 24.04 base with SSH server enabled, and PostgreSQL Server.
It allows you to easily create SSH-accessible containers via SSH keys or with a default username and password.

It is based on [this](https://github.com/aoudiamoncef/ubuntu-sshd) example, just added PostgreSQL on top of it.

<br/>

## Usage

### Build the image

Build the Docker image using `docker build -t pg-sshd-ubuntu:latest .`

### Run a container with it

To run a container based on the image, use the following command:

```bash
docker run -d \
  -p host-port:22 \
  -e SSH_USERNAME=myuser \
  -e SSH_PASSWORD=mysecretpassword \
  -e AUTHORIZED_KEYS="$(cat path/to/authorized_keys_file)" \
  -e SSHD_CONFIG_ADDITIONAL="your_additional_config" \
  -e SSHD_CONFIG_FILE="/path/to/your/sshd_config_file" \
  my-ubuntu-sshd:latest
```

-   `-d` runs the container in detached mode.
-   `-p host-port:22` maps a host port to port 22 in the container. Replace `host-port` with your desired port.
-   `-e SSH_USERNAME=myuser` sets the SSH username in the container. Replace `myuser` with your desired username.
-   `-e SSH_PASSWORD=mysecretpassword` sets the SSH user's password in the container. **This environment variable is
    required**. Replace `mysecretpassword` with your desired password.
-   `-e AUTHORIZED_KEYS="$(cat path/to/authorized_keys_file)"` sets authorized SSH keys in the container. Replace `path/to/authorized_keys_file` with the path to your authorized_keys file.
-   `-e SSHD_CONFIG_ADDITIONAL="your_additional_config"` allows you to pass additional SSHD configuration. Replace
    `your_additional_config` with your desired configuration.
-   `-e SSHD_CONFIG_FILE="/path/to/your/sshd_config_file"` allows you to specify a file containing additional SSHD
    configuration. Replace `/path/to/your/sshd_config_file` with the path to your configuration file.
-   `my-ubuntu-sshd:latest` should be replaced with your Docker image's name and tag.

### SSH Access

Once the container is running, you can SSH into it using the following command:

```bash
ssh -p host-port myuser@localhost
```

-   `host-port` should match the port you specified when running the container.
-   Use the provided password or SSH key for authentication, depending on your configuration.

### Note

-   If the `AUTHORIZED_KEYS` environment variable is empty when starting the container, it will still launch the SSH server, but no authorized keys will be configured. You have to mount your own authorized keys file or manually configure the keys in the container.
-   If `AUTHORIZED_KEYS` is provided, password authentication will be disabled for enhanced security.

## License

This Docker image is provided under the [MIT License](LICENSE).
