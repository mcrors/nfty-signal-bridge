FROM alpine:3.20
COPY --from=binwiederhier/ntfy:v2.11.0 /usr/bin/ntfy /usr/bin/ntfy
RUN apk add --no-cache jq curl bash
COPY forward.sh /opt/forward.sh
RUN chmod +x /opt/forward.sh
ENTRYPOINT ["ntfy", "subscribe", "--from-config"]
