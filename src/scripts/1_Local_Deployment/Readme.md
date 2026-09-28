# Deploying the container

## Build/Run Container

```
docker build --no-cache --platform linux/amd64 -t rjack-quest:local .

docker run --rm \
  --name rjack-quest \
  --platform linux/amd64 \
  -p 3000:3000 \
  rjack-quest:local

```

## Test

```
curl http://localhost:3000
```

## Stop Container

```
docker ps
docker stop <container-id>

```
