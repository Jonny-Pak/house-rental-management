package com.rental.modules.user.service;

import com.rental.modules.user.domain.entity.User;
import com.rental.modules.user.repository.UserRepository;
import com.rental.modules.user.repository.UserPreferenceRepository;
import com.rental.modules.subscription.repository.UserSubscriptionRepository;
import com.rental.modules.subscription.domain.entity.UserSubscription;
import com.rental.modules.subscription.domain.entity.MembershipPackage;
import org.junit.jupiter.api.Test;
import java.util.Optional;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class UserProfileMembershipTest {
    private final UserRepository users = mock(UserRepository.class);
    private final UserSubscriptionRepository subscriptions = mock(UserSubscriptionRepository.class);
    private final UserService service = new UserService(users, mock(UserPreferenceRepository.class), subscriptions);

    @Test
    void profileIncludesPurchasedPackageAndRemainingQuotas() {
        User user = new User();
        user.setUserId(7L);
        user.setEmail("member@example.com");
        when(users.countListingsForUser(7L)).thenReturn(3L);
        when(users.countContractsForUser(7L)).thenReturn(2L);
        when(users.countSavedListingsForUser(7L)).thenReturn(12L);
        when(users.findByEmail(user.getEmail())).thenReturn(Optional.of(user));
        MembershipPackage membership = new MembershipPackage();
        membership.setPackageName("Gói PRO");
        UserSubscription subscription = new UserSubscription();
        subscription.setMembershipPackage(membership);
        subscription.setRemainingStandardQuota(18);
        subscription.setRemainingVipQuota(3);
        subscription.setRemainingRefreshQuota(8);
        when(subscriptions.findByUser(user)).thenReturn(Optional.of(subscription));
        var profile = service.getMyProfile(user.getEmail());
        assertEquals(3L, profile.getListingCount());
        assertEquals(2L, profile.getContractCount());
        assertEquals(12L, profile.getSavedListingCount());
        assertEquals("Gói PRO", profile.getMembershipPackageName());
        assertEquals("ACTIVE", profile.getSubscriptionStatus());
        assertEquals(18, profile.getRemainingStandardQuota());
        assertEquals(3, profile.getRemainingVipQuota());
        assertEquals(8, profile.getRemainingRefreshQuota());
    }

    @Test
    void profileDoesNotInventPackageWhenNoSubscriptionExists() {
        User user = new User();
        user.setEmail("new@example.com");
        when(users.findByEmail(user.getEmail())).thenReturn(Optional.of(user));
        when(subscriptions.findByUser(user)).thenReturn(Optional.empty());
        var profile = service.getMyProfile(user.getEmail());
        assertNull(profile.getMembershipPackageName());
        assertNull(profile.getSubscriptionStatus());
        assertNull(profile.getRemainingStandardQuota());
    }
}
