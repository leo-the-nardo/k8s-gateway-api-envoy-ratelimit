package com.example.backend

import org.springframework.web.bind.annotation.*
import java.time.Instant

data class HealthResponse(
    val status: String,
    val timestamp: String,
    val podName: String,
    val namespace: String
)

data class EchoResponse(
    val message: String,
    val timestamp: String,
    val podName: String,
    val path: String,
    val method: String
)

@RestController
class BackendController {

    private val podName = System.getenv("POD_NAME") ?: "unknown"
    private val namespace = System.getenv("NAMESPACE") ?: "default"

    @GetMapping("/")
    fun root(): EchoResponse {
        return EchoResponse(
            message = "Hello from Kotlin Spring Boot Backend!",
            timestamp = Instant.now().toString(),
            podName = podName,
            path = "/",
            method = "GET"
        )
    }

    @GetMapping("/health")
    fun health(): HealthResponse {
        return HealthResponse(
            status = "UP",
            timestamp = Instant.now().toString(),
            podName = podName,
            namespace = namespace
        )
    }

    @GetMapping("/**")
    fun echo(@RequestParam allParams: Map<String, String>): EchoResponse {
        return EchoResponse(
            message = "Echo response with params: $allParams",
            timestamp = Instant.now().toString(),
            podName = podName,
            path = "/**",
            method = "GET"
        )
    }

    @PostMapping("/**")
    fun echoPost(@RequestBody(required = false) body: String?): EchoResponse {
        return EchoResponse(
            message = "Echo POST with body: ${body ?: "empty"}",
            timestamp = Instant.now().toString(),
            podName = podName,
            path = "/**",
            method = "POST"
        )
    }
}
