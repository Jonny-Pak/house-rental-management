package com.rental.modules.subscription.service;

import com.rental.modules.subscription.domain.entity.UserSubscription;
import com.rental.modules.subscription.repository.UserSubscriptionRepository;
import com.rental.modules.user.domain.entity.User;
import com.rental.modules.user.domain.enums.Role;
import com.rental.modules.user.domain.enums.UserStatus;
import com.rental.modules.user.repository.UserRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;
import java.time.LocalDateTime;

@Service
@Transactional
public class SubscriptionBenefitService {
    private final UserRepository users;
    private final UserSubscriptionRepository subscriptions;
    private final DefaultMembershipService defaults;

    public SubscriptionBenefitService(UserRepository users, UserSubscriptionRepository subscriptions,
            DefaultMembershipService defaults) {
        this.users = users;
        this.subscriptions = subscriptions;
        this.defaults = defaults;
    }

    public record Benefits(String packageName, String status, int standard, int vip, int refresh,
            LocalDateTime expiresAt) {}

    public Benefits getBenefits(Long userId) {
        UserSubscription subscription = findSubscription(userId);
        boolean active = isActive(subscription);
        return new Benefits(subscription.getPackageNameSnapshot(), active ? "ACTIVE" : "EXPIRED",
                active ? value(subscription.getRemainingStandardQuota()) : 0,
                active ? value(subscription.getRemainingVipQuota()) : 0,
                active ? value(subscription.getRemainingRefreshQuota()) : 0,
                subscription.getQuotaResetAt());
    }

    public LocalDateTime use(Long userId, String benefit) {
        UserSubscription subscription = findSubscription(userId);
        if (!isActive(subscription)) {
            throw new ResponseStatusException(HttpStatus.CONFLICT,
                    "Gói dịch vụ đã hết hạn. Vui lòng đăng ký gói mới.");
        }
        if ("STANDARD".equals(benefit)) {
            requireQuota(subscription.getRemainingStandardQuota(), "đăng tin");
            subscription.setRemainingStandardQuota(subscription.getRemainingStandardQuota() - 1);
        } else if ("VIP".equals(benefit)) {
            requireQuota(subscription.getRemainingVipQuota(), "nâng VIP");
            subscription.setRemainingVipQuota(subscription.getRemainingVipQuota() - 1);
        } else if ("REFRESH".equals(benefit)) {
            requireQuota(subscription.getRemainingRefreshQuota(), "làm mới tin");
            subscription.setRemainingRefreshQuota(subscription.getRemainingRefreshQuota() - 1);
        } else {
            throw new IllegalArgumentException("Quyền lợi không hợp lệ.");
        }
        subscriptions.save(subscription);
        return subscription.getQuotaResetAt();
    }

    private UserSubscription findSubscription(Long userId) {
        User user = users.findForAdminUpdate(userId).orElseThrow(() ->
                new ResponseStatusException(HttpStatus.NOT_FOUND, "Không tìm thấy tài khoản."));
        if (user.getRole() != Role.MEMBER || user.getStatus() != UserStatus.ACTIVE
                || !Boolean.TRUE.equals(user.getIsVerified())) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Tài khoản Member chưa đủ điều kiện sử dụng gói.");
        }
        defaults.assignIfMissing(userId);
        return subscriptions.findByUser(user).orElseThrow(() ->
                new ResponseStatusException(HttpStatus.CONFLICT, "Chưa có gói dịch vụ."));
    }

    private boolean isActive(UserSubscription subscription) {
        return "ACTIVE".equals(subscription.getStatus()) && (subscription.getQuotaResetAt() == null
                || subscription.getQuotaResetAt().isAfter(LocalDateTime.now()));
    }

    private int value(Integer quota) {
        return quota == null ? 0 : Math.max(0, quota);
    }

    private void requireQuota(Integer quota, String name) {
        if (value(quota) == 0) {
            throw new ResponseStatusException(HttpStatus.CONFLICT,
                    "Bạn đã hết lượt " + name + ". Vui lòng đăng ký thêm gói dịch vụ.");
        }
    }
}
