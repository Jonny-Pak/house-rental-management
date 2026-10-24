package com.rental.modules.payment;

import com.rental.modules.payment.config.VnPayConfig;
import com.rental.modules.payment.domain.entity.PaymentTransaction;
import com.rental.modules.payment.repository.PaymentTransactionRepository;
import com.rental.modules.payment.service.PaymentService;
import com.rental.modules.subscription.domain.entity.MembershipPackage;
import com.rental.modules.subscription.domain.entity.UserSubscription;
import com.rental.modules.subscription.repository.MembershipPackageRepository;
import com.rental.modules.subscription.repository.UserSubscriptionRepository;
import com.rental.modules.user.domain.entity.User;
import com.rental.modules.user.repository.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import java.math.BigDecimal;
import java.util.HashMap;
import java.util.Map;
import java.util.Optional;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class PaymentServiceTest {
    UserRepository users = mock(UserRepository.class);
    MembershipPackageRepository packages = mock(MembershipPackageRepository.class);
    UserSubscriptionRepository subscriptions = mock(UserSubscriptionRepository.class);
    PaymentTransactionRepository transactions = mock(PaymentTransactionRepository.class);
    VnPayConfig config = new VnPayConfig();
    PaymentService service = new PaymentService(config, transactions, users, packages, subscriptions);
    User user = new User();
    MembershipPackage pkg = new MembershipPackage();

    @BeforeEach void setup() {
        user.setUserId(7L);
        pkg.setPrice(BigDecimal.ZERO);
        pkg.setStandardPostQuota((short) 5);
        pkg.setVipPostQuota((short) 2);
        pkg.setRefreshQuota((short) 1);
        when(users.findByEmail("user@example.com")).thenReturn(Optional.of(user));
        when(packages.findById((short) 1)).thenReturn(Optional.of(pkg));
        when(subscriptions.findByUser(user)).thenReturn(Optional.empty());
        config.setVnp_HashSecret("test-secret");
    }

    private void checkQuotas() {
        ArgumentCaptor<UserSubscription> saved = ArgumentCaptor.forClass(UserSubscription.class);
        verify(subscriptions).save(saved.capture());
        assertEquals((short) 5, saved.getValue().getRemainingStandardQuota());
        assertEquals((short) 2, saved.getValue().getRemainingVipQuota());
        assertEquals((short) 1, saved.getValue().getRemainingRefreshQuota());
        assertEquals("ACTIVE", saved.getValue().getStatus());
        assertSame(user, saved.getValue().getUser());
        assertSame(pkg, saved.getValue().getMembershipPackage());
    }

    @Test void freePackageStillGrantsAllQuotas() {
        assertEquals("FREE_SUCCESS", service.createPaymentUrl("user@example.com", (short) 1, null));
        checkQuotas();
    }

    @Test void signedSuccessStillGrantsPaidPackageQuotas() {
        PaymentTransaction payment = new PaymentTransaction();
        payment.setUser(user);
        when(transactions.findByVnpayTransactionRef("1_7_123")).thenReturn(Optional.of(payment));
        Map<String, String> params = new HashMap<>();
        params.put("vnp_ResponseCode", "00");
        params.put("vnp_TxnRef", "1_7_123");
        params.put("vnp_SecureHash", config.hmacSHA512("test-secret", "vnp_ResponseCode=00&vnp_TxnRef=1_7_123"));
        assertTrue(service.processVnPayReturn(params));
        assertEquals("SUCCESS", payment.getStatus());
        checkQuotas();
    }

    @Test void invalidSignatureDoesNotGrantAnything() {
        Map<String, String> params = new HashMap<>();
        params.put("vnp_ResponseCode", "00");
        params.put("vnp_TxnRef", "1_7_123");
        params.put("vnp_SecureHash", "invalid");
        assertFalse(service.processVnPayReturn(params));
        verifyNoInteractions(subscriptions, transactions);
    }
}
