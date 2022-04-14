ARG SMARTMACHINE_VERSION

FROM smartmachine:$SMARTMACHINE_VERSION
LABEL maintainer="Timeboard <hello@timeboard.me>"

# Scheduler Essentials
RUN apk add --update busybox-suid && \
	apk add --update bash && \
    rm -rf /var/cache/apk/*

# Gems
RUN gem install whenever -v 1.0.0

CMD ["crond", "-f", "-l", "0", "-L", "/dev/stdout"]
