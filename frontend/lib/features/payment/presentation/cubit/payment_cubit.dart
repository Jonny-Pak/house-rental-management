import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/payment_repository.dart';
import 'payment_state.dart';

class PaymentCubit extends Cubit<PaymentState> {
  final PaymentRepository repository;
  PaymentCubit({required this.repository}) : super(PaymentInitial());

  Future<void> initiatePayment(int packageId) async {
    if (state is PaymentLoading) return;
    emit(PaymentLoading());
    try {
      final url = await repository.getVnPayUrl(packageId);
      if (isClosed) return;
      if (url == 'FREE_SUCCESS') {
        emit(PaymentSuccess(url));
        return;
      }
      final uri = Uri.tryParse(url);
      final reference = uri?.queryParameters['vnp_TxnRef'];
      if (uri == null ||
          uri.scheme != 'https' ||
          !['sandbox.vnpayment.vn', 'pay.vnpay.vn'].contains(uri.host) ||
          reference == null ||
          !RegExp(r'^[a-zA-Z0-9_-]{1,100}$').hasMatch(reference)) {
        emit(
          const PaymentError(
            'Đường dẫn thanh toán không hợp lệ. Vui lòng tải lại gói dịch vụ.',
          ),
        );
        return;
      }
      final opened = await repository.openPayment(uri);
      if (isClosed) return;
      if (opened) {
        emit(PaymentOpened(reference));
      } else {
        emit(
          const PaymentError(
            'Không mở được trình duyệt. Bạn có thể kiểm tra giao dịch trong lịch sử thanh toán.',
          ),
        );
      }
    } catch (error) {
      if (!isClosed) emit(PaymentError(error.toString()));
    }
  }
}
