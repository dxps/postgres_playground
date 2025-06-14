
docker run -d              \
  --name pg2               \
  --hostname pg2           \
  --ip 10.0.0.12           \
  --network=pgbrxp         \
  --add-host=pg1:10.0.0.11 \
  --add-host=pg3:10.0.0.13 \
  --add-host=pg4:10.0.0.14 \
  -p 2222:22               \
  pg-sshd-ubuntu:latest

