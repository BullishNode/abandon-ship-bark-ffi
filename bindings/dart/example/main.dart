import 'basic_example.dart';
import 'default_onchain_example.dart';
import 'custom_onchain_example.dart';

void main() async {
  try {
    // basic example - offchain only
    await basicExample();
    // default onchain example - uses an internal bdk-based wallet with default configuration
    // The default onchain example showcases the boarding process.
    await defaultOnchainExample();
    // custom onchain example - uses a user-provided wallet implementation
    // The custom onchain example showcases the unilateral exit functionality.
    await customOnchainExample();
  } catch (e, stackTrace) {
    print('\n=== ERROR ===');
    print('Error: $e');
    print('Type: ${e.runtimeType}');
    print('Stack trace: $stackTrace');
  }
}
