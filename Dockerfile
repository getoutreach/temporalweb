FROM node:16.15-alpine as builder
WORKDIR /usr/build

# install git & openssh to fetch github packages
RUN apk update && apk upgrade && \
    apk --no-cache add py-pip \ 
    build-base make g++ pkgconfig autoconf automake bash \ 
    imagemagick cairo-dev jpeg-dev pango-dev giflib-dev pixman-dev pangomm-dev libjpeg-turbo-dev freetype-dev \ 
    libc6-compat bash git openssh pixman cairo pango python3

# PhantomJS
RUN apk add --no-cache curl &&\
    cd /tmp && curl -Ls https://github.com/dustinblackman/phantomized/releases/download/2.1.1/dockerized-phantomjs.tar.gz | tar xz &&\
    cp -R lib lib64 / &&\
    cp -R usr/lib/x86_64-linux-gnu /usr/lib &&\
    cp -R usr/share /usr/share &&\
    cp -R etc/fonts /etc &&\
    curl -k -Ls https://bitbucket.org/ariya/phantomjs/downloads/phantomjs-2.1.1-linux-x86_64.tar.bz2 | tar -jxf - &&\
    cp phantomjs-2.1.1-linux-x86_64/bin/phantomjs /usr/local/bin/phantomjs

RUN ln -sf python3 /usr/bin/python

# Install app dependencies
COPY package*.json ./
RUN npm install --production --legacy-peer-deps

# Bundle app source
COPY . .
# Bundle the client code
ENV TEMPORAL_WEB_ROOT_PATH=/
# ENV TEMPORAL_WEB_ROOT_PATH=/custom-path-example/
RUN npm run build-production


# Build final image
FROM node:16.15-alpine
WORKDIR /usr/app

COPY --from=builder ./usr/build ./

ENV NODE_ENV=production
ENV NPM_CONFIG_PRODUCTION=true
ENV TEMPORAL_WEB_ROOT_PATH=/
# ENV TEMPORAL_WEB_ROOT_PATH=/custom-path-example/
EXPOSE 8088
CMD [ "node", "server.js" ]
