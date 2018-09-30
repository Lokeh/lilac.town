FROM clojure:tools-deps-alpine AS build

# Install npm
RUN apk add --update nodejs nodejs-npm

RUN mkdir -p /usr/app

WORKDIR /usr/app

# install npm deps
COPY package.json .

RUN npm install

COPY shadow-cljs.edn .

RUN npx shadow-cljs --cli-info

# install clojure deps
COPY deps.edn .

RUN clojure -R:server:uberjar -Spath

# build the thing
COPY ./src /usr/app/src 

COPY ./resources /usr/app/resources

COPY ./github_key /usr/app/github_key

RUN npx shadow-cljs release client bootstrap-support

RUN clojure -A:uberjar

## Create the deploy containerthing
FROM openjdk:8-alpine

# Pass in git commit SHA from build command
ARG GIT_COMMIT=unknown

ENV GIT_COMMIT=$GIT_COMMIT

COPY --from=build /usr/app/dist/lilactown.jar /lilactown.jar

CMD java -jar /lilactown.jar 3001 ${GIT_COMMIT}
