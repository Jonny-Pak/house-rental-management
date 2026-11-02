package com.rental.modules.content;

import com.rental.modules.content.service.ContentHtml;
import org.junit.jupiter.api.Test;
import org.springframework.web.server.ResponseStatusException;
import static org.junit.jupiter.api.Assertions.*;

class ContentHtmlTest {
    @Test void preservesOldPlainText() {
        assertEquals("Dòng 1\nDòng 2 <3", ContentHtml.clean("Dòng 1\nDòng 2 <3"));
    }
    @Test void preservesFormattingAndTables() {
        String html = ContentHtml.clean("<h2>Tiêu đề</h2><p style='color:#337788;text-align:center'>Xin <strong>chào</strong></p><table><tr><td colspan='2'>Nội dung</td></tr></table>");
        assertTrue(html.contains("<strong>chào</strong>"));
        assertTrue(html.contains("color:#337788;text-align:center;"));
        assertTrue(html.contains("colspan=\"2\""));
    }
    @Test void removesScriptsEventsRemoteImagesAndUnsafeStyles() {
        String html = ContentHtml.clean("<p onclick='alert(1)' style='background-image:url(https://bad.test);color:expression(alert(1))'>An toàn</p><script>alert(1)</script><img src='https://bad.test/a'><a href='javascript:alert(1)'>Link</a>");
        assertFalse(html.contains("script"));
        assertFalse(html.contains("onclick"));
        assertFalse(html.contains("bad.test"));
        assertFalse(html.contains("expression"));
        assertFalse(html.contains("javascript:"));
    }
    @Test void rejectsVisuallyEmptyHtml() {
        assertThrows(ResponseStatusException.class, () -> ContentHtml.clean("<p>&nbsp;</p>"));
    }
}
