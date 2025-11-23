FROM gradle:8.5-jdk17 AS build
WORKDIR /app
COPY build.gradle.kts settings.gradle.kts ./
COPY src ./src
RUN gradle build --no-daemon -x test

FROM eclipse-temurin:17-jre
WORKDIR /app

# Download Datadog Java APM agent
ADD https://dtdg.co/latest-java-tracer dd-java-agent.jar

COPY --from=build /app/build/libs/*.jar app.jar

EXPOSE 3000

# Configure Java to use Datadog agent
ENV JAVA_TOOL_OPTIONS="-javaagent:/app/dd-java-agent.jar"

ENTRYPOINT ["java", "-jar", "app.jar"]
