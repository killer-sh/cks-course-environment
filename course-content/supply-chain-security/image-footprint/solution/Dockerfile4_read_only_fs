# build container stage 1
FROM ubuntu:20.04
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y golang-go=2:1.13~1ubuntu2
COPY app.go .
RUN pwd
RUN CGO_ENABLED=0 go build app.go

# app container stage 2
FROM alpine:3.12.0
RUN chmod a-w /etc
RUN addgroup -S appgroup && adduser -S appuser -G appgroup -h /home/appuser
COPY --from=0 /app /home/appuser/
USER appuser
CMD ["/home/appuser/app"]
