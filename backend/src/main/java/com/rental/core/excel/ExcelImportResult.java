package com.rental.core.excel;

import java.util.List;

public record ExcelImportResult(int totalRows, int importedRows, List<RowPreview> rows, List<RowError> errors) {
    public record RowPreview(int row, String title, String description) {}
    public record RowError(int row, String message) {}
}
