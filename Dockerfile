FROM ubuntu AS build

RUN apt-get update
RUN apt-get install -y curl git unzip
RUN git clone https://github.com/flutter/flutter.git 
ENV PATH="/flutter/bin:${PATH}"
COPY . /app
WORKDIR /app
RUN flutter clean
RUN flutter build web
FROM nginx
EXPOSE 4444
COPY --from=build /app/build/web /usr/share/nginx/html