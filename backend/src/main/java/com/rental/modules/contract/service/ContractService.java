package com.rental.modules.contract.service;

import com.rental.modules.contract.dto.request.CreateContractRequest;
import com.rental.modules.contract.dto.response.ContractResponse;
import com.rental.modules.contract.domain.entity.Contract;
import com.rental.modules.contract.repository.ContractRepository;
import com.rental.modules.listing.domain.entity.Listing;
import com.rental.modules.listing.repository.ListingRepository;
import com.rental.modules.user.domain.entity.User;
import com.rental.modules.user.domain.enums.Role;
import com.rental.modules.user.domain.enums.UserStatus;
import com.rental.modules.user.repository.UserRepository;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Optional;

@Service
@Transactional
public class ContractService {
    @PersistenceContext
    private EntityManager entityManager;

    private final ContractRepository contracts;
    private final UserRepository users;
    private final ListingRepository listings;
    private final ContractDocumentService documents;

    private final com.rental.modules.notification.service.NotificationService notifications;

    public ContractService(ContractRepository contracts, UserRepository users, ListingRepository listings, ContractDocumentService documents, com.rental.modules.notification.service.NotificationService notifications) {
        this.notifications = notifications;
        this.contracts = contracts;
        this.users = users;
        this.listings = listings;
        this.documents = documents;
    }

    public ContractResponse createContract(String email, CreateContractRequest request) {
        validateRequest(request);
        User landlord = findUserByEmail(email);
        Listing listing = getOwnedListing(landlord, request.getListingId());
        checkListingAvailable(listing, -1L);
        User tenant = getValidTenant(request.getTenantId(), landlord);

        Contract contract = new Contract(
                listing, landlord, tenant,
                request.getStartDate(), request.getEndDate(),
                request.getMonthlyRent(), request.getDepositAmount(),
                "DRAFT", null, LocalDateTime.now());
        contract.setNote(request.getNote());
        documents.validate(request.getDetails(), contract.getStartDate(), contract.getEndDate());
        contracts.save(contract);
        documents.prepare(contract, request.getDetails());
        notifications.send(tenant.getUserId(), "CONTRACT_CREATED", "Hợp đồng cần bạn xác nhận", contract.getListingTitle(), null, contract.getId());
        return toResponse(contract, landlord);
    }

    public Map<String, String> previewContract(String email, CreateContractRequest request) {
        validateRequest(request);
        User landlord = findUserByEmail(email);
        Listing listing = getOwnedListing(landlord, request.getListingId());
        User tenant = getValidTenant(request.getTenantId(), landlord);
        Contract contract = new Contract(listing, landlord, tenant, request.getStartDate(), request.getEndDate(),
                request.getMonthlyRent(), request.getDepositAmount(), "DRAFT", null, LocalDateTime.now());
        contract.setNote(request.getNote());
        documents.prepare(contract, request.getDetails());
        return Map.of("contractType", contract.getContractType(), "content", contract.getDocumentText());
    }

    public ContractResponse getContract(String email, Long contractId) {
        User user = findUserByEmail(email);
        Contract contract = getAccessibleContract(user, contractId);
        return toResponse(contract, user);
    }

    public List<ContractResponse> getMyContracts(String email) {
        User user = findUserByEmail(email);

        List<Contract> mine = contracts.findByLandlordOrTenantOrderByListing_IdAscIdAsc(user, user);
        for (Contract contract : mine) {
            getAccessibleContract(user, contract.getId());
        }

        List<ContractResponse> result = new ArrayList<>();
        List<Contract> newestFirst = contracts.findByLandlordOrTenantOrderByIdDesc(user, user);
        for (Contract contract : newestFirst) {
            result.add(toResponse(contract, user));
        }
        return result;
    }

    public Map<String, Object> findTenant(String email, String tenantEmail, Long listingId) {
        return findTenant(email, tenantEmail, null, listingId);
    }

    public Map<String, Object> findTenant(String email, String tenantEmail, String phone, Long listingId) {
        User landlord = findUserByEmail(email);
        getOwnedListing(landlord, listingId);
        boolean hasEmail = tenantEmail != null && !tenantEmail.isBlank();
        boolean hasPhone = phone != null && !phone.isBlank();
        if (!hasEmail && !hasPhone) {
            throw error(HttpStatus.BAD_REQUEST, "Nhập email hoặc số điện thoại người thuê.");
        }
        if (hasEmail && hasPhone) {
            throw error(HttpStatus.BAD_REQUEST, "Nhập email hoặc số điện thoại người thuê.");
        }

        User found;
        if (hasEmail) {
            Optional<User> result = users.findByEmail(tenantEmail.trim());
            if (result.isEmpty()) {
                throw error(HttpStatus.NOT_FOUND, "Chưa có tài khoản với email này.");
            }
            found = result.get();
        } else {
            found = findUserByPhone(phone);
        }
        User tenant = getValidTenant(found.getUserId(), landlord);
        Map<String, Object> result = new HashMap<>();
        result.put("id", tenant.getUserId());
        result.put("name", tenant.getFullName());
        return result;
    }

    private User findUserByPhone(String phone) {
        List<String> phoneNumbers = getPhoneFormats(phone);
        List<User> matches = users.findByPhoneNumberIn(phoneNumbers);
        if (matches.isEmpty()) {
            throw error(HttpStatus.NOT_FOUND, "Chưa có tài khoản với số điện thoại này.");
        }
        if (matches.size() > 1) {
            throw error(HttpStatus.CONFLICT, "Số điện thoại trùng nhiều tài khoản. Hãy tìm bằng email.");
        }
        return matches.get(0);
    }

    private List<String> getPhoneFormats(String phone) {
        String input = phone.trim();
        String number = cleanPhoneNumber(input);
        checkPhoneNumber(number);
        String localNumber = toLocalPhoneNumber(number);

        List<String> formats = new ArrayList<>();
        formats.add(input);
        formats.add(number);
        formats.add(localNumber);
        if (localNumber.startsWith("0")) {
            String withoutLeadingZero = localNumber.substring(1);
            formats.add("+84" + withoutLeadingZero);
            formats.add("84" + withoutLeadingZero);
        }
        return formats;
    }

    private String cleanPhoneNumber(String phone) {
        String number = phone.replace(" ", "");
        number = number.replace("-", "");
        number = number.replace(".", "");
        number = number.replace("(", "");
        number = number.replace(")", "");
        return number;
    }

    private void checkPhoneNumber(String number) {
        String digits = number;
        if (number.startsWith("+")) {
            digits = number.substring(1);
        }
        if (digits.length() < 9 || digits.length() > 15) {
            throw error(HttpStatus.BAD_REQUEST, "Số điện thoại không hợp lệ.");
        }
        for (int index = 0; index < digits.length(); index++) {
            char character = digits.charAt(index);
            if (character < '0' || character > '9') {
                throw error(HttpStatus.BAD_REQUEST, "Số điện thoại không hợp lệ.");
            }
        }
    }

    private String toLocalPhoneNumber(String number) {
        if (number.startsWith("+84")) {
            return "0" + number.substring(3);
        }
        if (number.startsWith("84") && number.length() == 11) {
            return "0" + number.substring(2);
        }
        return number;
    }

    public ContractResponse updateContract(String email, Long contractId, CreateContractRequest request) {
        validateRequest(request);
        User landlord = findUserByEmail(email);
        Contract contract = getAccessibleContract(landlord, contractId);

        if (!isLandlord(contract, landlord)) {
            throw error(HttpStatus.FORBIDDEN, "Chỉ chủ nhà được sửa bản nháp.");
        }
        if (!"DRAFT".equals(contract.getStatus())) {
            throw error(HttpStatus.CONFLICT, "Chỉ sửa được hợp đồng chờ xác nhận.");
        }
        if (!contract.getListing().getId().equals(request.getListingId())) {
            throw error(HttpStatus.BAD_REQUEST, "Không đổi tin đăng của hợp đồng; hãy hủy và tạo bản mới.");
        }

        checkListingAvailable(contract.getListing(), contractId);
        User tenant = getValidTenant(request.getTenantId(), landlord);
        Long previousTenant = contract.getTenant().getUserId();
        contract.setTenant(tenant);
        contract.setStartDate(request.getStartDate());
        contract.setEndDate(request.getEndDate());
        contract.setMonthlyRent(request.getMonthlyRent());
        contract.setDepositAmount(request.getDepositAmount());
        contract.setNote(request.getNote());
        documents.prepare(contract, request.getDetails());
        notifications.send(tenant.getUserId(), "CONTRACT_UPDATED", "Hợp đồng đã được cập nhật", "Hãy kiểm tra lại nội dung trước khi xác nhận: " + contract.getListingTitle(), null, contract.getId());
        if (!previousTenant.equals(tenant.getUserId())) {
            notifications.send(previousTenant, "CONTRACT_UPDATED", "Hợp đồng đã thay đổi người thuê", "Bạn không còn tham gia hợp đồng cho " + contract.getListingTitle(), null, null);
        }
        return toResponse(contract, landlord);
    }

    public ContractResponse changeStatus(String email, Long contractId, String status, Long version) {
        User user = findUserByEmail(email);
        Contract contract = getAccessibleContract(user, contractId);
        if (!Objects.equals(contract.getVersion(), version)) {
            throw error(HttpStatus.CONFLICT, "Hợp đồng đã thay đổi. Hãy tải lại và kiểm tra trước khi xác nhận.");
        }

        if ("ACTIVE".equals(status)) {
            activateContract(contract, user);
        } else if ("CANCELLED".equals(status)) {
            cancelContract(contract);
        } else if ("TERMINATED".equals(status)) {
            terminateContract(contract, user);
        } else {
            throw error(HttpStatus.BAD_REQUEST, "Trạng thái không hợp lệ.");
        }
        Long recipient = isLandlord(contract, user) ? contract.getTenant().getUserId() : contract.getLandlord().getUserId();
        String title = switch (status) {
            case "ACTIVE" -> "Người thuê đã xác nhận hợp đồng";
            case "CANCELLED" -> "Hợp đồng đã bị hủy";
            default -> "Hợp đồng đã kết thúc";
        };
        notifications.send(recipient, "CONTRACT_" + status, title, contract.getListingTitle(), null, contract.getId());
        return toResponse(contract, user);
    }

    private void activateContract(Contract contract, User user) {
        if (isLandlord(contract, user)) {
            throw error(HttpStatus.FORBIDDEN, "Người thuê cần xác nhận hợp đồng.");
        }
        if (!"DRAFT".equals(contract.getStatus())) {
            throw error(HttpStatus.CONFLICT, "Hợp đồng không còn chờ xác nhận hoặc đã quá hạn.");
        }
        if (!contract.getEndDate().isAfter(today())) {
            throw error(HttpStatus.CONFLICT, "Hợp đồng không còn chờ xác nhận hoặc đã quá hạn.");
        }
        checkListingAvailable(contract.getListing(), contract.getId());
        if (contract.getDocumentText() == null || contract.getDocumentText().isBlank()) {
            throw error(HttpStatus.CONFLICT, "Chủ nhà cần bổ sung hợp đồng theo mẫu trước khi xác nhận.");
        }
        contract.setAcceptedAt(LocalDateTime.now(ZoneId.of("Asia/Ho_Chi_Minh")));
        contract.setStatus("ACTIVE");
        contract.getListing().setRentalStatus("RENTED");
    }

    private void cancelContract(Contract contract) {
        if (!"DRAFT".equals(contract.getStatus())) {
            throw error(HttpStatus.CONFLICT, "Chỉ hủy được hợp đồng chờ xác nhận.");
        }
        contract.setStatus("CANCELLED");
    }

    private void terminateContract(Contract contract, User user) {
        if (!isLandlord(contract, user)) {
            throw error(HttpStatus.FORBIDDEN, "Chỉ chủ nhà được kết thúc hợp đồng.");
        }
        if (!"ACTIVE".equals(contract.getStatus())) {
            throw error(HttpStatus.CONFLICT, "Hợp đồng không còn hiệu lực.");
        }
        contract.setStatus("TERMINATED");
        hideListingAfterContract(contract);
    }

    private User findUserByEmail(String email) {
        Optional<User> found = users.findByEmail(email);
        if (found.isEmpty()) {
            throw error(HttpStatus.NOT_FOUND, "Không tìm thấy tài khoản.");
        }
        return found.get();
    }

    private Listing getOwnedListing(User landlord, Long listingId) {
        Optional<Listing> found = listings.findLockedById(listingId);
        if (found.isEmpty()) {
            throw error(HttpStatus.NOT_FOUND, "Không tìm thấy tin đăng.");
        }
        Listing listing = found.get();
        if (!listing.getOwner().getUserId().equals(landlord.getUserId())) {
            throw error(HttpStatus.FORBIDDEN, "Bạn chỉ được tạo hợp đồng cho tin của mình.");
        }
        return listing;
    }

    private User getValidTenant(Long tenantId, User landlord) {
        Optional<User> found = users.findById(tenantId);
        if (found.isEmpty()) {
            throw error(HttpStatus.NOT_FOUND, "Không tìm thấy người thuê.");
        }
        User tenant = found.get();
        boolean sameUser = tenantId.equals(landlord.getUserId());
        boolean isAdmin = tenant.getRole() == Role.ADMIN;
        boolean inactive = tenant.getStatus() != UserStatus.ACTIVE;
        if (sameUser || isAdmin || inactive) {
            throw error(HttpStatus.BAD_REQUEST, "Tài khoản người thuê không hợp lệ.");
        }
        return tenant;
    }

    private void validateRequest(CreateContractRequest request) {
        LocalDate start = request.getStartDate();
        LocalDate end = request.getEndDate();
        if (start == null || end == null) {
            throw error(HttpStatus.BAD_REQUEST, "Ngày kết thúc phải sau ngày bắt đầu và ngày hiện tại.");
        }
        if (!end.isAfter(start) || !end.isAfter(today())) {
            throw error(HttpStatus.BAD_REQUEST, "Ngày kết thúc phải sau ngày bắt đầu và ngày hiện tại.");
        }
        if (request.getMonthlyRent() == null || request.getDepositAmount() == null) {
            throw error(HttpStatus.BAD_REQUEST, "Tiền thuê phải lớn hơn 0, tiền cọc không được âm.");
        }
        if (request.getMonthlyRent().signum() <= 0 || request.getDepositAmount().signum() < 0) {
            throw error(HttpStatus.BAD_REQUEST, "Tiền thuê phải lớn hơn 0, tiền cọc không được âm.");
        }
    }

    private void checkListingAvailable(Listing listing, Long excludedContractId) {
        boolean approved = "APPROVED".equals(listing.getApprovalStatus());
        boolean available = "AVAILABLE".equals(listing.getRentalStatus());
        if (!approved || !available) {
            throw error(HttpStatus.CONFLICT, "Tin phải được duyệt và đang cho thuê để tạo hợp đồng.");
        }
        boolean alreadyBooked = contracts.existsByListing_IdAndStatusInAndIdNot(
                listing.getId(), List.of("DRAFT", "ACTIVE"), excludedContractId);
        if (alreadyBooked) {
            throw error(HttpStatus.CONFLICT, "Tin này đã có hợp đồng chờ xác nhận hoặc đang hiệu lực.");
        }
    }

    private Contract getAccessibleContract(User user, Long contractId) {
        Optional<Contract> found = contracts.findById(contractId);
        if (found.isEmpty()) {
            throw error(HttpStatus.NOT_FOUND, "Không tìm thấy hợp đồng.");
        }
        Contract initial = found.get();
        checkParticipant(initial, user);

        Listing listing = listings.findLockedById(initial.getListing().getId()).orElseThrow();
        entityManager.refresh(listing);
        Contract contract = contracts.findLockedById(contractId).orElseThrow();
        entityManager.refresh(contract);
        checkParticipant(contract, user);
        expireIfNeeded(contract);
        return contract;
    }

    private void checkParticipant(Contract contract, User user) {
        boolean landlord = isLandlord(contract, user);
        boolean tenant = contract.getTenant().getUserId().equals(user.getUserId());
        if (!landlord && !tenant) {
            throw error(HttpStatus.FORBIDDEN, "Bạn không thuộc hợp đồng này.");
        }
    }

    private boolean isLandlord(Contract contract, User user) {
        return contract.getLandlord().getUserId().equals(user.getUserId());
    }

    private void expireIfNeeded(Contract contract) {
        if (!"ACTIVE".equals(contract.getStatus())) {
            return;
        }
        if (contract.getEndDate().isBefore(today())) {
            contract.setStatus("EXPIRED");
            hideListingAfterContract(contract);
            notifications.send(contract.getLandlord().getUserId(), "CONTRACT_EXPIRED", "Hợp đồng đã hết hạn", contract.getListingTitle(), null, contract.getId());
            notifications.send(contract.getTenant().getUserId(), "CONTRACT_EXPIRED", "Hợp đồng đã hết hạn", contract.getListingTitle(), null, contract.getId());
        }
    }

    private void hideListingAfterContract(Contract contract) {
        Listing listing = contract.getListing();
        if (!"RENTED".equals(listing.getRentalStatus())) {
            return;
        }
        boolean otherActiveContract = contracts.existsByListing_IdAndStatusInAndIdNot(
                listing.getId(), List.of("ACTIVE"), contract.getId());
        if (!otherActiveContract) {
            listing.setRentalStatus("HIDDEN");
        }
    }

    private ContractResponse toResponse(Contract contract, User user) {
        contracts.flush();
        String role = "TENANT";
        if (isLandlord(contract, user)) {
            role = "LANDLORD";
        }
        var details = documents.readDetails(contract);
        return new ContractResponse(
                contract.getId(), contract.getListing().getId(),
                contract.getListingTitle(), contract.getListingAddress(),
                contract.getLandlord().getUserId(), details == null ? contract.getLandlord().getFullName() : details.getLandlordName(),
                contract.getTenant().getUserId(), details == null ? contract.getTenant().getFullName() : details.getTenantName(),
                contract.getStartDate(), contract.getEndDate(),
                contract.getMonthlyRent(), contract.getDepositAmount(),
                contract.getStatus(), contract.getNote(), contract.getCreatedAt(),
                role, contract.getVersion(), contract.getContractType(), details, contract.getDocumentText(), contract.getAcceptedAt());
    }

    private LocalDate today() {
        return LocalDate.now(ZoneId.of("Asia/Ho_Chi_Minh"));
    }

    private ResponseStatusException error(HttpStatus status, String message) {
        return new ResponseStatusException(status, message);
    }
}
