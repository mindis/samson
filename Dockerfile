FROM erlang:22
WORKDIR /app
COPY rebar.config rebar.lock ./
COPY src ./src
COPY config ./config
RUN rebar3 compile && rebar3 release && ln -s /app/_build/default/rel/samson/bin/samson /usr/local/bin/samson
ENTRYPOINT ["samson"]
CMD ["foreground"]
