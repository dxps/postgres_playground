
docker run -d              \
  --name pg4               \
  --hostname pg4           \
  --ip 10.0.0.14           \
  --network=pgbrxp         \
  --add-host=pg1:10.0.0.11 \
  --add-host=pg2:10.0.0.12 \
  --add-host=pg3:10.0.0.13 \
  -p 2224:22               \
  pg-sshd-ubuntu:latest

