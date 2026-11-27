import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/auth/auth_cubit.dart';
import '../blocs/cart/cart_bloc.dart';
import '../blocs/orders/orders_cubit.dart';
import '../models/delivery_info.dart';
import '../models/order.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';
import '../utils/validators.dart';

/// Тапсырыс беру формасы.
///
///   Себет ──«Рәсімдеу»──▶ CheckoutScreen ──валидация──▶ OrdersCubit.placeOrder()
///                                                   └──▶ CartBloc: ClearCartEvent
///   Сәтті болса — `Navigator.pop(context, order)`: себет экраны растау терезесін шығарады.
///
/// Форманың өрістері — ephemeral state (тек осы экранға керек), сондықтан
/// StatefulWidget + TextEditingController жеткілікті; BLoC-қа шығармаймыз.
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController(text: 'Алматы');
  final _addressController = TextEditingController();
  final _commentController = TextEditingController();

  DeliveryMethod _method = DeliveryMethod.courier;
  PaymentMethod _payment = PaymentMethod.cardOnDelivery;
  bool _submitting = false;

  /// Бірінші «Растау» басылғанға дейін қателерді көрсетпейміз —
  /// пайдаланушы әлі тере бастамай жатып қызыл жазу шықпауы үшін.
  AutovalidateMode _autovalidate = AutovalidateMode.disabled;

  @override
  void initState() {
    super.initState();
    // Кірген пайдаланушының атын алдын ала толтырамыз.
    final auth = context.read<AuthCubit>().state;
    if (auth is AuthSuccess) _nameController.text = auth.username;
  }

  @override
  void dispose() {
    for (final c in [
      _nameController,
      _phoneController,
      _cityController,
      _addressController,
      _commentController,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit(CartState cart) async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) {
      setState(() => _autovalidate = AutovalidateMode.onUserInteraction);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Қызыл белгіленген өрістерді түзетіңіз')));
      return;
    }

    final courier = _method == DeliveryMethod.courier;
    final delivery = DeliveryInfo(
      fullName: _nameController.text.trim(),
      phone: Validators.normalizePhone(_phoneController.text),
      method: _method,
      city: courier ? _cityController.text.trim() : '',
      address: courier ? _addressController.text.trim() : '',
      payment: _payment,
      comment: _commentController.text.trim(),
    );

    setState(() => _submitting = true);
    final OrderRecord order;
    try {
      order = await context.read<OrdersCubit>().placeOrder(cart.items, delivery: delivery);
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: Colors.red.shade700,
        content: const Text('Тапсырысты сақтау мүмкін болмады. Қайталап көріңіз.'),
      ));
      return;
    }
    if (!mounted) return;
    // Тапсырыс сақталды — енді ғана себетті тазалаймыз.
    context.read<CartBloc>().add(const ClearCartEvent());
    Navigator.pop(context, order);
  }

  @override
  Widget build(BuildContext context) {
    // Себет тазаланғанда (тапсырыстан кейін) бос себетті сызбау үшін buildWhen.
    return BlocBuilder<CartBloc, CartState>(
      buildWhen: (_, next) => !next.isEmpty,
      builder: (context, cart) {
        final fee = DeliveryInfo.feeFor(_method, cart.totalPrice);
        return Scaffold(
          appBar: AppBar(title: const Text('Тапсырыс беру')),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Form(
                key: _formKey,
                autovalidateMode: _autovalidate,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  children: [
                    _section(context, Icons.person_outline, 'Байланыс'),
                    TextFormField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.name],
                      decoration: const InputDecoration(
                        labelText: 'Аты-жөні',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                      validator: Validators.fullName,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.telephoneNumber],
                      inputFormatters: [KzPhoneInputFormatter()],
                      decoration: const InputDecoration(
                        labelText: 'Телефон',
                        hintText: '(701) 123-45-67',
                        prefixText: '+7 ',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                      validator: Validators.phone,
                    ),
                    const SizedBox(height: 20),
                    _section(context, Icons.local_shipping_outlined, 'Жеткізу'),
                    SegmentedButton<DeliveryMethod>(
                      segments: const [
                        ButtonSegment(
                          value: DeliveryMethod.courier,
                          icon: Icon(Icons.delivery_dining),
                          label: Text('Курьер'),
                        ),
                        ButtonSegment(
                          value: DeliveryMethod.pickup,
                          icon: Icon(Icons.storefront_outlined),
                          label: Text('Өзім аламын'),
                        ),
                      ],
                      selected: {_method},
                      onSelectionChanged: (s) => setState(() => _method = s.first),
                    ),
                    const SizedBox(height: 12),
                    // Курьер таңдалса ғана мекенжай өрістері көрінеді және тексеріледі.
                    AnimatedSize(
                      duration: const Duration(milliseconds: 200),
                      alignment: Alignment.topCenter,
                      child: _method == DeliveryMethod.courier
                          ? Column(
                              children: [
                                TextFormField(
                                  controller: _cityController,
                                  textInputAction: TextInputAction.next,
                                  decoration: const InputDecoration(
                                    labelText: 'Қала',
                                    prefixIcon: Icon(Icons.location_city_outlined),
                                  ),
                                  validator: Validators.city,
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _addressController,
                                  textInputAction: TextInputAction.next,
                                  autofillHints: const [AutofillHints.fullStreetAddress],
                                  decoration: const InputDecoration(
                                    labelText: 'Мекенжай',
                                    hintText: 'Абай даңғылы, 10, пәтер 5',
                                    prefixIcon: Icon(Icons.home_outlined),
                                  ),
                                  validator: Validators.address,
                                ),
                              ],
                            )
                          : Card(
                              margin: EdgeInsets.zero,
                              color: context.surfaceCard,
                              child: const ListTile(
                                leading: Icon(Icons.storefront),
                                title: Text('Алу нүктесі'),
                                subtitle: Text(DeliveryInfo.pickupPoint),
                              ),
                            ),
                    ),
                    const SizedBox(height: 20),
                    _section(context, Icons.payments_outlined, 'Төлем'),
                    for (final p in PaymentMethod.values)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        onTap: () => setState(() => _payment = p),
                        leading: Icon(
                          p == _payment ? Icons.radio_button_checked : Icons.radio_button_off,
                          color: p == _payment ? context.accent : Colors.grey,
                        ),
                        title: Text(p.label),
                        trailing: Icon(
                          p == PaymentMethod.cash ? Icons.payments_outlined : Icons.credit_card,
                          color: Colors.grey,
                        ),
                      ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _commentController,
                      maxLines: 2,
                      maxLength: 200,
                      decoration: const InputDecoration(
                        labelText: 'Пікір (міндетті емес)',
                        hintText: 'Мысалы: подъезд коды, қоңырау шалу уақыты',
                        prefixIcon: Icon(Icons.chat_bubble_outline),
                      ),
                      validator: Validators.comment,
                    ),
                    const SizedBox(height: 12),
                    _Summary(cart: cart, fee: fee, method: _method),
                  ],
                ),
              ),
            ),
          ),
          bottomNavigationBar: SafeArea(
            minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: FilledButton.icon(
              onPressed: _submitting ? null : () => _submit(cart),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primary,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                    )
                  : const Icon(Icons.check_circle_outline),
              label: Text(
                _submitting ? 'Сақталуда…' : 'Растау · ${formatPrice(cart.totalPrice + fee)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _section(BuildContext context, IconData icon, String title) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            Icon(icon, size: 20, color: context.accent),
            const SizedBox(width: 8),
            Flexible(
              child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
}

/// Сома: кітаптар + жеткізу = жалпы.
class _Summary extends StatelessWidget {
  final CartState cart;
  final int fee;
  final DeliveryMethod method;

  const _Summary({required this.cart, required this.fee, required this.method});

  @override
  Widget build(BuildContext context) {
    final grey = TextStyle(color: Colors.grey.shade600);
    final left = DeliveryInfo.freeDeliveryFrom - cart.totalPrice;

    Widget row(String label, String value, {TextStyle? style}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            children: [
              Expanded(child: Text(label, style: style ?? grey)),
              Text(value, style: style),
            ],
          ),
        );

    return Card(
      margin: EdgeInsets.zero,
      color: context.surfaceCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            row('Кітаптар (${cart.count} дана)', formatPrice(cart.totalPrice)),
            row('Жеткізу', fee == 0 ? 'Тегін' : formatPrice(fee)),
            if (method == DeliveryMethod.courier && left > 0)
              Padding(
                padding: const EdgeInsets.only(top: 2, bottom: 4),
                child: Text(
                  'Тағы ${formatPrice(left)} — жеткізу тегін',
                  style: TextStyle(fontSize: 12.5, color: context.accent),
                ),
              ),
            const Divider(),
            row(
              'Жалпы',
              formatPrice(cart.totalPrice + fee),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: context.accent),
            ),
          ],
        ),
      ),
    );
  }
}
