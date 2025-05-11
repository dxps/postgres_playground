
docker run -d              \
  --name pgs               \
  --hostname pgs           \
  -p 2224:22               \
  -e SSH_USERNAME=postgres \
  -e SSH_PASSWORD=pgpass   \
  my-ubuntu-sshd:latest

