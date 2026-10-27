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
        pkg.setId((short) 1);
        pkg.setPackageName("Gói PLUS");
        pkg.setPrice(BigDecimal.ZERO);
        pkg.setStandardPostQuota((short) 5);
        pkg.setVipPostQuota((short) 2);
        pkg.setRefreshQuota((short) 1);
        when(users.findByEmail("user@example.com")).thenReturn(Optional.of(user));
        when(packages.findForUpdate((short) 1)).thenReturn(Optional.of(pkg));
        when(users.findForAdminUpdate(7L)).thenReturn(Optional.of(user));
        when(subscriptions.findByUser(user)).thenReturn(Optional.empty());
        config.setVnp_HashSecret("test-secret");
    }

    private void checkQuotas() {
        ArgumentCaptor<UserSubscription> saved = ArgumentCaptor.forClass(UserSubscription.class);
        verify(subscriptions).save(saved.capture());
        assertEquals(5, saved.getValue().getRemainingStandardQuota());
        assertEquals(2, saved.getValue().getRemainingVipQuota());
        assertEquals(1, saved.getValue().getRemainingRefreshQuota());
        assertEquals("ACTIVE", saved.getValue().getStatus());
        assertSame(user, saved.getValue().getUser());
        assertSame(pkg, saved.getValue().getMembershipPackage());
    }

    @Test void freePackageStillGrantsAllQuotas() {
        assertEquals("FREE_SUCCESS", service.createPaymentUrl("user@example.com", (short) 1, null));
        checkQuotas();
    }

    private PaymentTransaction paidTransaction() {
        PaymentTransaction payment = new PaymentTransaction();
        payment.setUser(user); payment.setAmount(new BigDecimal("50000"));
        payment.setPurchasedPackage(pkg); payment.setPackageNameSnapshot("Gói PLUS");
        payment.setStandardQuotaSnapshot((short) 5); payment.setVipQuotaSnapshot((short) 2); payment.setRefreshQuotaSnapshot((short) 1);
        when(transactions.findForUpdate("1_7_123")).thenReturn(Optional.of(payment));
        return payment;
    }
    private Map<String, String> signed(String amount) {
        Map<String, String> params = new HashMap<>();
        params.put("vnp_Amount", amount); params.put("vnp_ResponseCode", "00"); params.put("vnp_TxnRef", "1_7_123");
        params.put("vnp_SecureHash", config.hmacSHA512("test-secret", "vnp_Amount=" + amount + "&vnp_ResponseCode=00&vnp_TxnRef=1_7_123"));
        return params;
    }
    @Test void signedSuccessStillGrantsPaidPackageQuotas() {
        PaymentTransaction payment = paidTransaction();
        assertTrue(service.processVnPayReturn(signed("5000000")));
        assertEquals("SUCCESS", payment.getStatus());
        checkQuotas();
        assertTrue(service.processVnPayReturn(signed("5000000")));
        verify(subscriptions, times(1)).save(any());
    }
    @Test void packageEditsAndStoppingSalesDoNotChangePendingPurchase() {
        paidTransaction();
        pkg.setStandardPostQuota((short) 100); pkg.setPackageName("Gói mới"); pkg.setActive(false);
        assertTrue(service.processVnPayReturn(signed("5000000")));
        checkQuotas();
        ArgumentCaptor<UserSubscription> result = ArgumentCaptor.forClass(UserSubscription.class);
        verify(subscriptions).save(result.capture());
        assertEquals("Gói PLUS", result.getValue().getPackageNameSnapshot());
    }
    @Test void hiddenPackagesCannotStartNewPayments() {
        pkg.setActive(false);
        assertThrows(org.springframework.web.server.ResponseStatusException.class, () -> service.createPaymentUrl("user@example.com", (short) 1, null));
        verifyNoInteractions(transactions, subscriptions);
    }
    @Test void deletedPackageReturnsNotFoundWithoutCreatingTransaction() {
        when(packages.findForUpdate((short) 1)).thenReturn(Optional.empty());
        var error = assertThrows(org.springframework.web.server.ResponseStatusException.class, () -> service.createPaymentUrl("user@example.com", (short) 1, null));
        assertEquals(404, error.getStatusCode().value()); verifyNoInteractions(transactions, subscriptions);
    }
    @Test void wrongAmountDoesNotGrantQuotasEvenWithValidSignature() {
        PaymentTransaction payment = paidTransaction();
        assertFalse(service.processVnPayReturn(signed("1")));
        assertEquals("PENDING", payment.getStatus()); verify(subscriptions, never()).save(any());
    }
    @Test void cumulativeBalancesDoNotOverflowSmallint() {
        UserSubscription existing = new UserSubscription(); existing.setRemainingStandardQuota(32765);
        when(subscriptions.findByUser(user)).thenReturn(Optional.of(existing));
        assertEquals("FREE_SUCCESS", service.createPaymentUrl("user@example.com", (short) 1, null));
        assertEquals(32770, existing.getRemainingStandardQuota());
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
