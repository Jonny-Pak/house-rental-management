package com.rental;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableAsync;

@SpringBootApplication
@EnableAsync
public class HouseRentalManagementApplication {

    public static void main(String[] args) {
        SpringApplication.run(HouseRentalManagementApplication.class, args);
    }
}
