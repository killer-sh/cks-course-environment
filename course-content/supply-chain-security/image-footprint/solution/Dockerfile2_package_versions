# build container stage 1
FROM ubuntu
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y golang-go
COPY app.go .
RUN CGO_ENABLED=0 go build app.go

# app container stage 2
FROM alpine:3.11.6
COPY --from=0 /app .
CMD ["./app"]
