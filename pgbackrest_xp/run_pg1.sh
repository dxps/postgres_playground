
docker run -d              \
  --name pg1               \
  --hostname pg1           \
  --ip 10.0.0.11           \
  --network=pgbrxp         \
  --add-host=pg2:10.0.0.12 \
  --add-host=pg3:10.0.0.13 \
  --add-host=pg3:10.0.0.13 \
  --add-host=pg4:10.0.0.14 \
  -p 2221:22               \
  pg-sshd-ubuntu:latest

