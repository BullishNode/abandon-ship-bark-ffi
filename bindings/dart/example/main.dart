import 'basic_example.dart';
import 'default_onchain_example.dart';
import 'custom_onchain_example.dart';

void main() async {
  try {
    await basicExample();
    await defaultOnchainExample();
    await customOnchainExample();
  } catch (e, stackTrace) {
    print('\n=== ERROR ===');
    print('Error: $e');
    print('Type: ${e.runtimeType}');
    print('Stack trace: $stackTrace');
  }
}
