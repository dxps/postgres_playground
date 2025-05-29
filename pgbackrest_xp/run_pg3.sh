
docker run -d              \
  --name pg3               \
  --hostname pg3           \
  --ip 10.0.0.13           \
  --network=pgbrxp         \
  --add-host=pg1:10.0.0.11 \
  --add-host=pg2:10.0.0.12 \
  -p 2223:22               \
  -e SSH_USERNAME=postgres \
  -e SSH_PASSWORD=pgpass   \
  pg-sshd-ubuntu:latest

