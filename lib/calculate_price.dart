import 'package:flutter/material.dart';
import 'package:eco_move_frontend/l10n/context_ext.dart';

class ChargeCalculatorScreen extends StatefulWidget {
  final String tipoCarga;
  final String precio;

  const ChargeCalculatorScreen({
    super.key,
    required this.tipoCarga,
    required this.precio,
  });

  @override
  ChargeCalculatorScreenState createState() => ChargeCalculatorScreenState();
}

class ChargeCalculatorScreenState extends State<ChargeCalculatorScreen> {
  final TextEditingController batteryCapacityController =
      TextEditingController();
  final TextEditingController currentPercentageController =
      TextEditingController();
  final TextEditingController desiredPercentageController =
      TextEditingController();

  double? pricePerKWh = 0.0697;

  void _showPriceDialog(double price) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(context.loc.calc_price_title),
          content: Text(
            '${context.loc.calc_price_total_is}: €${price.toStringAsFixed(2)}',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _calculatePrice() {
    double batteryCapacity =
        double.tryParse(batteryCapacityController.text) ?? 0;
    double currentPercentage =
        double.tryParse(currentPercentageController.text) ?? 0;
    double desiredPercentage =
        double.tryParse(desiredPercentageController.text) ?? 0;

    if (batteryCapacity <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.loc.calc_error_capacity)));
      return;
    }

    if (currentPercentage < 0 ||
        currentPercentage > 100 ||
        desiredPercentage < 0 ||
        desiredPercentage > 100 ||
        desiredPercentage <= currentPercentage) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.loc.calc_error_percentages)),
      );
      return;
    }

    if (pricePerKWh != null) {
      double energyRequired =
          (desiredPercentage - currentPercentage) / 100 * batteryCapacity;
      double price = energyRequired * pricePerKWh!;

      _showPriceDialog(price);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.loc.calc_error_no_price)));
    }
  }

  @override
  void dispose() {
    batteryCapacityController.dispose();
    currentPercentageController.dispose();
    desiredPercentageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.loc.calc_price_title)),
      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: const Color(0xffbcccf7),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(
                        '${context.loc.calc_type}: ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(widget.tipoCarga),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text(
                        '${context.loc.calc_price}: ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        pricePerKWh != null
                            ? '€${pricePerKWh!.toStringAsFixed(2)} / kWh'
                            : context.loc.station_loading,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildInputField(
              context.loc.calc_capacity_label,
              batteryCapacityController,
              'Ej: 60',
            ),
            const SizedBox(height: 25),
            _buildInputField(
              context.loc.calc_current_label,
              currentPercentageController,
              'Ej: 20',
            ),
            const SizedBox(height: 25),
            _buildInputField(
              context.loc.calc_target_label,
              desiredPercentageController,
              'Ej: 80',
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: _calculatePrice,
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xff6d89d6),
                foregroundColor: Colors.white,
              ),
              child: Text(context.loc.calc_button),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(
    String label,
    TextEditingController controller,
    String hintText,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(color: Colors.grey),
            border: const OutlineInputBorder(),
          ),
        ),
      ],
    );
  }
}
