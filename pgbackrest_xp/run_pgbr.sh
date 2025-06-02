
docker run -d              \
  --name pgbr              \
  --hostname pgbr          \
  -p 2223:22               \
  -e SSH_USERNAME=postgres \
  -e SSH_PASSWORD=pgpass   \
  pg-sshd-ubuntu:latest

