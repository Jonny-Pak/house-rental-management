import 'package:equatable/equatable.dart';

abstract class PaymentState extends Equatable {
  const PaymentState();

  @override
  List<Object?> get props => [];
}

class PaymentInitial extends PaymentState {}

class PaymentLoading extends PaymentState {}

class PaymentSuccess extends PaymentState {
  final String paymentUrl;

  const PaymentSuccess(this.paymentUrl);

  @override
  List<Object?> get props => [paymentUrl];
}

class PaymentError extends PaymentState {
  final String message;

  const PaymentError(this.message);

  @override
  List<Object?> get props => [message];
}

class PaymentOpened extends PaymentState {
  const PaymentOpened(this.reference);
  final String reference;
  @override
  List<Object?> get props => [reference];
}
