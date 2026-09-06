package com.rental.modules.user.dto.request;

import com.rental.modules.user.domain.enums.Role;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class RegisterRequest {

    @NotBlank(message = "Cần phải nhâp tên đầy đủ")
    @Size(max = 150, message = "Tên đầy đủ không được vượt quá 150 ký tự")
    private String fullName;

    @NotBlank(message = "Cần phải nhâp email")
    @Email(message = "Email phải là một địa chỉ email hợp lệ")
    @Size(max = 150, message = "Email không được vượt quá 150 ký tự")
    private String email;

    @NotBlank(message = "Cần phải nhâp password")
    @Size(min = 8, message = "Password không được ít hơn 8 ký tự")
    private String password;

    @Size(max = 15, message = "Số điện thoại không được vượt quá 15 ký tự")
    private String phoneNumber;

    @NotNull(message = "Cần phải nhâp role")
    private Role role;
}
