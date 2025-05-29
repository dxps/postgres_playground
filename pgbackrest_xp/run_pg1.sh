
docker run -d              \
  --name pg1               \
  --hostname pg1           \
  --ip 10.0.0.11           \
  --network=pgbrxp         \
  --add-host=pg2:10.0.0.12 \
  --add-host=pg3:10.0.0.13 \
  -p 2221:22               \
  -e SSH_USERNAME=postgres \
  -e SSH_PASSWORD='pgpass' \
  pg-sshd-ubuntu:latest

