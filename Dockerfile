# ---- Build stage ----
FROM maven:3.9.11-amazoncorretto-21 AS build

WORKDIR /app

COPY .mvn/ .mvn/
COPY mvnw pom.xml ./
RUN chmod +x mvnw

COPY src/ src/

RUN ./mvnw -DskipTests clean package && \
    JAR_FILE=$(find target -maxdepth 1 -type f -name '*.jar' ! -name '*sources.jar' ! -name '*javadoc.jar' | head -n 1) && \
    cp "$JAR_FILE" /app/app.jar

# ---- Runtime stage ----
FROM amazoncorretto:21

WORKDIR /app

COPY --from=build /app/app.jar /app/app.jar

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "/app/app.jar"]