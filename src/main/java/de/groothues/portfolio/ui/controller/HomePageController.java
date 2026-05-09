package de.groothues.portfolio.ui.controller;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;

@Controller
class HomePageController {

    @GetMapping("/")
    String home() {
        return "home";
    }
}
