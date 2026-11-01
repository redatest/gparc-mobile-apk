import 'package:flutter_test/flutter_test.dart';
import 'package:gparc_mobile/main.dart';

void main() {
  testWidgets('Application widget can be constructed', (tester) async {
    const app = GparcApp();
    expect(app, isA<GparcApp>());
  });
}
