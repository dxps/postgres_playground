
docker run -d              \
  --name pg2               \
  --hostname pg2           \
  -p 2222:22               \
  -e SSH_USERNAME=postgres \
  -e SSH_PASSWORD=pgpass   \
  my-ubuntu-sshd:latest

