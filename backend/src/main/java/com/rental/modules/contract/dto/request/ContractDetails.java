package com.rental.modules.contract.dto.request;

public class ContractDetails {
    @jakarta.validation.constraints.Size(max=500)
    private String landlordIdentity;
    @jakarta.validation.constraints.Size(max=500)
    private String landlordAddress;
    @jakarta.validation.constraints.Size(max=500)
    private String tenantIdentity;
    @jakarta.validation.constraints.Size(max=500)
    private String tenantAddress;
    @jakarta.validation.constraints.Size(max=255)
    private String signingPlace;
    @jakarta.validation.constraints.Size(max=10)
    private String signingDate;
    @jakarta.validation.constraints.Size(max=10)
    private String handoverDate;
    @jakarta.validation.constraints.Size(max=1000)
    private String paymentMethod;
    @jakarta.validation.constraints.Size(max=1000)
    private String electricityTerms;
    @jakarta.validation.constraints.Size(max=1000)
    private String waterTerms;
    @jakarta.validation.constraints.Size(max=1000)
    private String serviceFees = "Không thu thêm nếu hai bên không có thỏa thuận bằng văn bản.";
    @jakarta.validation.constraints.Size(max=1000)
    private String conditionDescription = "Hiện trạng được hai bên kiểm tra và ghi nhận khi bàn giao.";
    @jakarta.validation.constraints.Size(max=1000)
    private String equipment = "Theo danh mục hai bên kiểm tra và ghi nhận khi bàn giao.";
    @jakarta.validation.constraints.Size(max=2000)
    private String useRules = "Sử dụng để ở; giữ vệ sinh, an ninh, phòng cháy; không sửa chữa hoặc cho thuê lại khi chưa có thỏa thuận hợp lệ.";
    @jakarta.validation.constraints.Size(max=2000)
    private String depositTerms = "Đối chiếu tiền thuê, điện nước và tài sản khi bàn giao; hoàn lại tiền cọc còn lại. Các khoản khấu trừ phải có căn cứ và được hai bên xác nhận.";
    @jakarta.validation.constraints.Size(max=2000)
    private String terminationTerms = "Báo trước 30 ngày theo thỏa thuận; đối chiếu nghĩa vụ và lập biên bản bàn giao khi kết thúc, phù hợp quy định pháp luật áp dụng.";
    @jakarta.validation.constraints.Size(max=2000)
    private String violationTerms = "Bồi thường thiệt hại thực tế do lỗi của bên vi phạm. Các khoản phạt khác phải được hai bên thỏa thuận hợp pháp.";
    @jakarta.validation.constraints.Size(max=255)
    private String landlordName;
    @jakarta.validation.constraints.Size(max=30)
    private String landlordPhone;
    @jakarta.validation.constraints.Size(max=255)
    private String tenantName;
    @jakarta.validation.constraints.Size(max=30)
    private String tenantPhone;
    @jakarta.validation.constraints.Min(1)
    @jakarta.validation.constraints.Max(28)
    private int paymentDay = 5;
    public String getLandlordIdentity() { return landlordIdentity; }
    public void setLandlordIdentity(String value) { landlordIdentity = value; }
    public String getLandlordAddress() { return landlordAddress; }
    public void setLandlordAddress(String value) { landlordAddress = value; }
    public String getTenantIdentity() { return tenantIdentity; }
    public void setTenantIdentity(String value) { tenantIdentity = value; }
    public String getTenantAddress() { return tenantAddress; }
    public void setTenantAddress(String value) { tenantAddress = value; }
    public String getSigningPlace() { return signingPlace; }
    public void setSigningPlace(String value) { signingPlace = value; }
    public String getSigningDate() { return signingDate; }
    public void setSigningDate(String value) { signingDate = value; }
    public String getHandoverDate() { return handoverDate; }
    public void setHandoverDate(String value) { handoverDate = value; }
    public String getPaymentMethod() { return paymentMethod; }
    public void setPaymentMethod(String value) { paymentMethod = value; }
    public String getElectricityTerms() { return electricityTerms; }
    public void setElectricityTerms(String value) { electricityTerms = value; }
    public String getWaterTerms() { return waterTerms; }
    public void setWaterTerms(String value) { waterTerms = value; }
    public String getServiceFees() { return serviceFees; }
    public void setServiceFees(String value) { serviceFees = value; }
    public String getConditionDescription() { return conditionDescription; }
    public void setConditionDescription(String value) { conditionDescription = value; }
    public String getEquipment() { return equipment; }
    public void setEquipment(String value) { equipment = value; }
    public String getUseRules() { return useRules; }
    public void setUseRules(String value) { useRules = value; }
    public String getDepositTerms() { return depositTerms; }
    public void setDepositTerms(String value) { depositTerms = value; }
    public String getTerminationTerms() { return terminationTerms; }
    public void setTerminationTerms(String value) { terminationTerms = value; }
    public String getViolationTerms() { return violationTerms; }
    public void setViolationTerms(String value) { violationTerms = value; }
    public String getLandlordName() { return landlordName; }
    public void setLandlordName(String value) { landlordName = value; }
    public String getLandlordPhone() { return landlordPhone; }
    public void setLandlordPhone(String value) { landlordPhone = value; }
    public String getTenantName() { return tenantName; }
    public void setTenantName(String value) { tenantName = value; }
    public String getTenantPhone() { return tenantPhone; }
    public void setTenantPhone(String value) { tenantPhone = value; }
    public int getPaymentDay() { return paymentDay; }
    public void setPaymentDay(int value) { paymentDay = value; }
}
