package com.rental.modules.contract.service;

import com.rental.modules.contract.domain.entity.Contract;
import com.rental.modules.contract.dto.response.ContractResponse;
import com.rental.modules.contract.repository.ContractRepository;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

@Service
@Transactional(readOnly = true)
public class AdminContractService {
    private final ContractRepository contracts;
    private final ContractDocumentService documents;

    public AdminContractService(ContractRepository contracts, ContractDocumentService documents) {
        this.contracts = contracts;
        this.documents = documents;
    }

    public record ContractPage(List<ContractResponse> items, long total, int page, int totalPages) {}

    public ContractPage search(String query, String status, String type, int page) {
        if (query.length() > 100 || page < 0 || page > 10000
                || !List.of("", "DRAFT", "ACTIVE", "EXPIRED", "CANCELLED", "TERMINATED").contains(status)
                || !List.of("", "HOUSE", "ROOM").contains(type)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Bộ lọc hợp đồng không hợp lệ.");
        }
        String text = query.trim().toLowerCase(Locale.ROOT);
        Long id = -1L;
        String number = text.startsWith("#") ? text.substring(1) : text;
        try { id = Long.parseLong(number); } catch (NumberFormatException ignored) {}
        LocalDate today = LocalDate.now(ZoneId.of("Asia/Ho_Chi_Minh"));
        var rows = contracts.searchAdmin(text, id, status, type, today,
            PageRequest.of(page, 20, Sort.by(Sort.Direction.DESC, "id")));
        List<ContractResponse> items = new ArrayList<>();
        for (Contract contract : rows) items.add(response(contract, today, false));
        return new ContractPage(items, rows.getTotalElements(), page, rows.getTotalPages());
    }

    public ContractResponse detail(Long id) {
        Contract contract = contracts.findAdminDetail(id).orElseThrow(() ->
            new ResponseStatusException(HttpStatus.NOT_FOUND, "Không tìm thấy hợp đồng."));
        return response(contract, LocalDate.now(ZoneId.of("Asia/Ho_Chi_Minh")), true);
    }

    private ContractResponse response(Contract contract, LocalDate today, boolean full) {
        String status = contract.getStatus();
        if ("ACTIVE".equals(status) && contract.getEndDate().isBefore(today)) status = "EXPIRED";
        var details = documents.readDetails(contract);
        String landlord = details == null ? contract.getLandlord().getFullName() : details.getLandlordName();
        String tenant = details == null ? contract.getTenant().getFullName() : details.getTenantName();
        if (landlord == null || landlord.isBlank()) landlord = contract.getLandlord().getFullName();
        if (tenant == null || tenant.isBlank()) tenant = contract.getTenant().getFullName();
        String type = contract.getContractType();
        if (type == null) {
            String listingType = contract.getListing().getListingType();
            type = "BOARDING_ROOM".equals(listingType) || "SHARED_ROOM".equals(listingType) ? "ROOM" : "HOUSE";
        }
        return new ContractResponse(contract.getId(), contract.getListing().getId(),
            contract.getListingTitle(), contract.getListingAddress(),
            contract.getLandlord().getUserId(), landlord, contract.getTenant().getUserId(), tenant,
            contract.getStartDate(), contract.getEndDate(), contract.getMonthlyRent(), contract.getDepositAmount(),
            status, full ? contract.getNote() : null, contract.getCreatedAt(), "ADMIN", contract.getVersion(),
            type, full ? details : null, full ? contract.getDocumentText() : null, contract.getAcceptedAt());
    }
}
