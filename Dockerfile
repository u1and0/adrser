FROM nimlang/nim:latest-alpine AS nimbuilder
WORKDIR /tmp
COPY ./adrser.nim /tmp/adrser.nim
RUN nimble install -y xlsx jester
RUN nim c -d:release adrser.nim

FROM node:18-alpine3.15 AS tsbuilder
COPY ./static /tmp/static
WORKDIR /tmp/static
RUN npm install -D typescript ts-node ts-node-dev fzf
RUN npx tsc || exit 0  # Ignore TypeScript build error

FROM alpine:latest
RUN apk --update --no-cache add libzip-dev
COPY ./static/favicon.png /var/www/static/favicon.png
COPY --from=tsbuilder /tmp/static/node_modules /var/www/static/node_modules
COPY --from=tsbuilder /tmp/static/dist/main.js /var/www/static/dist/main.js
COPY --from=nimbuilder /tmp/adrser /usr/bin/adrser
RUN chmod +x /usr/bin/adrser
WORKDIR /var/www
ENTRYPOINT ["/usr/bin/adrser"]

LABEL maintainer="u1and0 <e01.ando60@gmail.com>" \
      description="Fuzzy Search xlsx address data on browser\
                    住所録検索サーバー" \
      version="adrser:v0.1.0" \
      usage="docker run -d -p 3333:3333 u1and0/adrser -l=1000 -d=/path/to/xslx"
