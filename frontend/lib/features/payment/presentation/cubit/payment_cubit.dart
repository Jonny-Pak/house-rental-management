import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/repositories/payment_repository.dart';
import 'payment_state.dart';

class PaymentCubit extends Cubit<PaymentState> {
  final PaymentRepository repository;

  PaymentCubit({required this.repository}) : super(PaymentInitial());

  Future<void> initiatePayment(int packageId) async {
    emit(PaymentLoading());
    try {
      final url = await repository.getVnPayUrl(packageId);
      final uri = Uri.parse(url);
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        emit(PaymentSuccess(url));
      } else {
        emit(const PaymentError('Không thể mở trình duyệt để thanh toán'));
      }
    } catch (e) {
      emit(PaymentError(e.toString()));
    }
  }
}
