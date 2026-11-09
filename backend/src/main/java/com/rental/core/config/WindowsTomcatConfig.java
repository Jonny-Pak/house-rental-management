package com.rental.core.config;

import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.boot.web.embedded.tomcat.TomcatServletWebServerFactory;
import org.springframework.boot.web.server.WebServerFactoryCustomizer;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/** Avoid the JDK selector's Unix-domain loopback pipe on Windows. */
@Configuration
@ConditionalOnProperty(name = "rental.server.windows-nio2", havingValue = "true", matchIfMissing = true)
public class WindowsTomcatConfig {
    @Bean
    WebServerFactoryCustomizer<TomcatServletWebServerFactory> windowsTomcatProtocol() {
        return factory -> {
            if (System.getProperty("os.name", "").startsWith("Windows")) {
                factory.setProtocol("org.apache.coyote.http11.Http11Nio2Protocol");
            }
        };
    }
}
