ARG SMARTMACHINE_VERSION

FROM smartmachine/smartengine:$SMARTMACHINE_VERSION
LABEL maintainer="Timeboard <support@timeboard.me>"

# Ruby on Rails Essentials
RUN apk add --update build-base && \
	apk add --update tzdata && \
	apk add --update nodejs && \
	apk add --update yarn && \
	apk add --update mariadb-dev && \
	apk add --update imagemagick && \
	apk add --update ffmpeg && \
	apk add --update mupdf && \
	apk add --update mupdf-tools && \
    rm -rf /var/cache/apk/*

# Gems
RUN gem install bundler -v 2.1.4

CMD ["smartmachine", "buildpacker", "packer", "rails"]
