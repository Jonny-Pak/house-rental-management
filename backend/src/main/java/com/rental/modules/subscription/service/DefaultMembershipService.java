package com.rental.modules.subscription.service;

import com.rental.modules.subscription.domain.entity.MembershipPackage;
import com.rental.modules.subscription.domain.entity.UserSubscription;
import com.rental.modules.subscription.repository.MembershipPackageRepository;
import com.rental.modules.subscription.repository.UserSubscriptionRepository;
import com.rental.modules.user.domain.entity.User;
import com.rental.modules.user.domain.enums.Role;
import com.rental.modules.user.domain.enums.UserStatus;
import com.rental.modules.user.repository.UserRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class DefaultMembershipService {
    private final UserRepository users;
    private final MembershipPackageRepository packages;
    private final UserSubscriptionRepository subscriptions;

    public DefaultMembershipService(UserRepository users, MembershipPackageRepository packages, UserSubscriptionRepository subscriptions) {
        this.users = users;
        this.packages = packages;
        this.subscriptions = subscriptions;
    }

    @Transactional
    public void assignIfMissing(Long userId) {
        User user = users.findForAdminUpdate(userId).orElseThrow();
        if (user.getRole() != Role.MEMBER || user.getStatus() != UserStatus.ACTIVE
                || !Boolean.TRUE.equals(user.getIsVerified())) return;
        if (subscriptions.findByUser(user).isPresent()) return;
        MembershipPackage item = packages.findByDefaultPackageTrue()
                .orElseThrow(() -> new IllegalStateException("Chưa có gói Cơ bản mặc định."));
        UserSubscription subscription = new UserSubscription();
        subscription.setUser(user);
        subscription.setMembershipPackage(item);
        subscription.setPackageNameSnapshot(item.getPackageName());
        subscription.setRemainingStandardQuota(item.getStandardPostQuota().intValue());
        subscription.setRemainingVipQuota(item.getVipPostQuota().intValue());
        subscription.setRemainingRefreshQuota(item.getRefreshQuota().intValue());
        subscription.setQuotaResetAt(null);
        subscription.setStatus("ACTIVE");
        subscriptions.save(subscription);
    }
}
