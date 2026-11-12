FROM alpine:3.20

COPY worker.sh /usr/local/bin/worker.sh
RUN chmod +x /usr/local/bin/worker.sh

ENV DIR=/data
VOLUME /data

CMD ["/usr/local/bin/worker.sh"]
