package com.rental.modules.content.service;

import org.jsoup.Jsoup;
import org.jsoup.nodes.Document;
import org.jsoup.nodes.Element;
import org.jsoup.safety.Safelist;
import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;

public final class ContentHtml {
    private ContentHtml() {}

    public static String clean(String value) {
        String body = value.trim();
        if (!body.matches("(?s).*<[a-zA-Z][^>]*>.*")) return body;
        Safelist allowed = Safelist.none().addTags("p", "br", "h2", "h3", "h4", "strong", "b",
            "em", "i", "u", "s", "span", "ul", "ol", "li", "blockquote", "hr",
            "figure", "table", "thead", "tbody", "tr", "td", "th", "a")
            .addAttributes(":all", "style")
            .addAttributes("a", "href", "title").addProtocols("a", "href", "http", "https", "mailto")
            .addEnforcedAttribute("a", "rel", "nofollow noopener noreferrer")
            .addAttributes("td", "colspan", "rowspan").addAttributes("th", "colspan", "rowspan");
        Document document = Jsoup.parseBodyFragment(Jsoup.clean(body, allowed));
        document.outputSettings().prettyPrint(false);
        for (Element element : document.select("[style]")) {
            StringBuilder safeStyle = new StringBuilder();
            for (String declaration : element.attr("style").split(";")) {
                String[] pair = declaration.split(":", 2);
                if (pair.length != 2) continue;
                String name = pair[0].trim().toLowerCase(java.util.Locale.ROOT);
                String setting = pair[1].trim();
                boolean valid = switch (name) {
                    case "color", "background-color" -> setting.matches("#[0-9a-fA-F]{3,8}|[a-zA-Z]{1,20}|(?:rgb|hsl)a?\\([0-9.,% /]+\\)");
                    case "text-align" -> setting.matches("left|right|center|justify");
                    case "font-size" -> setting.matches("[0-9]{1,2}(?:px|pt)|tiny|small|big|huge");
                    case "font-family" -> setting.matches("[a-zA-Z ,'-]{1,100}");
                    case "margin-left" -> setting.matches("[0-9]{1,3}px");
                    default -> false;
                };
                if (valid) safeStyle.append(name).append(':').append(setting).append(';');
            }
            element.removeAttr("style");
            if (!safeStyle.isEmpty()) element.attr("style", safeStyle.toString());
        }
        if (document.body().text().isBlank()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Vui lòng nhập nội dung.");
        }
        String result = document.body().html();
        if (result.length() > 20000) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Nội dung tối đa 20.000 ký tự, bao gồm định dạng.");
        }
        return result;
    }
}
