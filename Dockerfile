FROM node:16.15.1-alpine as builder
WORKDIR /usr/build

# install git & openssh to fetch github packages
RUN apk update && apk upgrade && \
    apk --no-cache add py-pip \ 
    build-base make g++ pkgconfig autoconf automake bash \ 
    imagemagick cairo-dev jpeg-dev pango-dev giflib-dev pixman-dev pangomm-dev libjpeg-turbo-dev freetype-dev \ 
    libc6-compat && \  
    apk add --no-cache bash git openssh pixman cairo pango python3

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
FROM node:16.15.1-alpine
WORKDIR /usr/app

COPY --from=builder ./usr/build ./

ENV NODE_ENV=production
ENV NPM_CONFIG_PRODUCTION=true
ENV TEMPORAL_WEB_ROOT_PATH=/
# ENV TEMPORAL_WEB_ROOT_PATH=/custom-path-example/
EXPOSE 8088
CMD [ "node", "server.js" ]
