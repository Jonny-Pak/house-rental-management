package com.rental.modules.subscription;

import com.rental.modules.subscription.domain.entity.*;
import com.rental.modules.subscription.repository.*;
import com.rental.modules.subscription.service.DefaultMembershipService;
import com.rental.modules.user.domain.entity.User;
import com.rental.modules.user.domain.enums.*;
import com.rental.modules.user.repository.UserRepository;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import java.util.Optional;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class DefaultMembershipServiceTest {
    UserRepository users = mock(UserRepository.class);
    MembershipPackageRepository packages = mock(MembershipPackageRepository.class);
    UserSubscriptionRepository subscriptions = mock(UserSubscriptionRepository.class);
    DefaultMembershipService service = new DefaultMembershipService(users, packages, subscriptions);

    User member() {
        User user = new User();
        user.setUserId(7L); user.setRole(Role.MEMBER);
        user.setStatus(UserStatus.ACTIVE); user.setIsVerified(true);
        when(users.findForAdminUpdate(7L)).thenReturn(Optional.of(user));
        return user;
    }

    @Test void activatedMemberReceivesConfiguredQuotasOnce() {
        User user = member();
        MembershipPackage item = new MembershipPackage();
        item.setPackageName("Basic"); item.setStandardPostQuota((short) 3);
        item.setVipPostQuota((short) 0); item.setRefreshQuota((short) 0);
        when(packages.findByDefaultPackageTrue()).thenReturn(Optional.of(item));
        when(subscriptions.findByUser(user)).thenReturn(Optional.empty(), Optional.of(new UserSubscription()));
        service.assignIfMissing(7L);
        service.assignIfMissing(7L);
        var saved = ArgumentCaptor.forClass(UserSubscription.class);
        verify(subscriptions).save(saved.capture());
        assertSame(user, saved.getValue().getUser());
        assertSame(item, saved.getValue().getMembershipPackage());
        assertEquals("Basic", saved.getValue().getPackageNameSnapshot());
        assertEquals(3, saved.getValue().getRemainingStandardQuota());
        assertEquals(0, saved.getValue().getRemainingVipQuota());
        assertEquals(0, saved.getValue().getRemainingRefreshQuota());
        assertEquals("ACTIVE", saved.getValue().getStatus());
        assertNull(saved.getValue().getQuotaResetAt());
    }

    @Test void existingSubscriptionAndUsedQuotasArePreserved() {
        User user = member();
        UserSubscription paid = new UserSubscription();
        paid.setPackageNameSnapshot("PRO"); paid.setRemainingStandardQuota(0);
        when(subscriptions.findByUser(user)).thenReturn(Optional.of(paid));
        service.assignIfMissing(7L);
        assertEquals("PRO", paid.getPackageNameSnapshot());
        assertEquals(0, paid.getRemainingStandardQuota());
        verify(subscriptions, never()).save(any());
        verifyNoInteractions(packages);
    }

    @Test void unverifiedLockedAndAdminAccountsDoNotReceiveMembership() {
        User user = member(); user.setIsVerified(false);
        service.assignIfMissing(7L);
        user.setIsVerified(true); user.setStatus(UserStatus.LOCKED);
        service.assignIfMissing(7L);
        user.setStatus(UserStatus.ACTIVE); user.setRole(Role.ADMIN);
        service.assignIfMissing(7L);
        verifyNoInteractions(packages, subscriptions);
    }
}
