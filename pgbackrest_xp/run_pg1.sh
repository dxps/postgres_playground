
docker run -d              \
  --name pg1               \
  --hostname pg1           \
  -p 2221:22               \
  -e SSH_USERNAME=postgres \
  -e SSH_PASSWORD=pgpass   \
  my-ubuntu-sshd:latest

