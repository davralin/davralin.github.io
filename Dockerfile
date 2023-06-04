FROM docker.io/debian:stable-slim
RUN apt update && \
    apt install ruby-full build-essential zlib1g-dev git -y
RUN gem install jekyll bundler
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
CMD /usr/local/bin/entrypoint.sh