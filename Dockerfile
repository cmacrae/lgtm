FROM golang:alpine as builder
RUN apk add --no-cache git ca-certificates && update-ca-certificates
ENV UID=10001
RUN adduser \
	--disabled-password \
	--gecos "" \
	--home "/nonexistent" \
	--shell "/sbin/nologin" \
	--no-create-home \
	--uid 10001 \
	lgtm

WORKDIR /lgtm
COPY main.go go.mod go.sum  /lgtm/
COPY templates /lgtm/templates
RUN go mod download
RUN go mod verify
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -a -installsuffix cgo -o lgtm
RUN chown -R lgtm:lgtm /lgtm

FROM scratch
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=builder /etc/passwd /etc/passwd
COPY --from=builder /etc/group /etc/group
COPY --from=builder /lgtm /lgtm
WORKDIR /lgtm
USER lgtm:lgtm
EXPOSE 8080
ENTRYPOINT ["/lgtm/lgtm"]
