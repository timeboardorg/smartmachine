ARG SMARTMACHINE_VERSION

FROM smartmachine/smartengine:$SMARTMACHINE_VERSION
LABEL maintainer="Gaurav Goel <gaurav@timeboard.me>"

# FCGI Essentials
# --- IMPORTANT NOTE: This is custom built fcgiwrap package for alpine linux to account for NO_BUFFERING option.
# --- Original fcgiwrap: https://github.com/gnosek/fcgiwrap
# --- Custom fcgiwrap: https://github.com/notr1ch/fcgiwrap
COPY fcgiwrap /root/apk-packages/fcgiwrap
RUN apk add fcgiwrap --repository /root/apk-packages/fcgiwrap/packages/main --allow-untrusted && \
	rm -rf /root/apk-packages
RUN apk add --update coreutils && \
	apk add --update util-linux && \
	apk add --update git && \
	apk add --update git-daemon && \
    apk add --update spawn-fcgi && \
    rm -rf /var/cache/apk/*

CMD ["spawn-fcgi", "-n", "-p", "9000", "/usr/bin/fcgiwrap", "-f"]
