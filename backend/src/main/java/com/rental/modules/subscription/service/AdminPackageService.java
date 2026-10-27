package com.rental.modules.subscription.service;

import com.rental.modules.subscription.domain.entity.MembershipPackage;
import com.rental.modules.subscription.dto.SavePackageRequest;
import com.rental.modules.subscription.repository.*;
import com.rental.modules.payment.repository.PaymentTransactionRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.data.domain.*;
import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;
import java.util.*;

@Service
@Transactional
public class AdminPackageService {
    private final MembershipPackageRepository packages;
    private final UserSubscriptionRepository subscriptions;
    private final PaymentTransactionRepository payments;
    public AdminPackageService(MembershipPackageRepository packages, UserSubscriptionRepository subscriptions, PaymentTransactionRepository payments) {
        this.packages = packages; this.subscriptions = subscriptions; this.payments = payments;
    }
    public record PackagePage(List<MembershipPackage> items, long total, int page, int totalPages) {}
    @Transactional(readOnly = true)
    public PackagePage list(String query, Boolean active, int page) {
        if (query.length() > 100 || page < 0 || page > 10000) throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Bộ lọc không hợp lệ.");
        Page<MembershipPackage> found = packages.search(query.trim(), active, PageRequest.of(page, 20));
        return new PackagePage(found.getContent(), found.getTotalElements(), page, found.getTotalPages());
    }
    public MembershipPackage create(SavePackageRequest request) {
        if (packages.existsByPackageNameIgnoreCase(request.packageName().trim())) duplicate();
        MembershipPackage item = new MembershipPackage();
        apply(item, request);
        return packages.saveAndFlush(item);
    }
    public MembershipPackage update(Short id, SavePackageRequest request) {
        MembershipPackage item = find(id, request.version());
        if (packages.existsByPackageNameIgnoreCaseAndIdNot(request.packageName().trim(), id)) duplicate();
        apply(item, request);
        return packages.saveAndFlush(item);
    }
    public MembershipPackage changeStatus(Short id, boolean active, Long version) {
        MembershipPackage item = find(id, version);
        item.setActive(active);
        return packages.saveAndFlush(item);
    }
    public void delete(Short id, Long version) {
        MembershipPackage item = find(id, version);
        if (subscriptions.existsByMembershipPackageId(id) || payments.existsByPurchasedPackageId(id)) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Gói đã có người mua hoặc giao dịch. Hãy ngừng bán để giữ lịch sử.");
        }
        packages.delete(item);
        packages.flush();
    }
    private MembershipPackage find(Short id, Long version) {
        Optional<MembershipPackage> found = packages.findForUpdate(id);
        if (found.isEmpty()) throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Không tìm thấy gói dịch vụ.");
        if (version == null || !version.equals(found.get().getVersion())) throw new ResponseStatusException(HttpStatus.CONFLICT, "Gói đã thay đổi. Hãy tải lại trước khi thao tác.");
        return found.get();
    }
    private void apply(MembershipPackage item, SavePackageRequest request) {
        if (request.standardPostQuota() + request.vipPostQuota() + request.refreshQuota() == 0) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Gói cần có ít nhất một lượt đăng tin hoặc làm mới.");
        }
        item.setPackageName(request.packageName().trim());
        item.setPrice(request.price());
        item.setStandardPostQuota(request.standardPostQuota().shortValue());
        item.setVipPostQuota(request.vipPostQuota().shortValue());
        item.setRefreshQuota(request.refreshQuota().shortValue());
        item.setDescription(request.description() == null ? "" : request.description().trim());
        item.setActive(request.active());
    }
    private void duplicate() { throw new ResponseStatusException(HttpStatus.CONFLICT, "Tên gói dịch vụ đã tồn tại."); }
}
