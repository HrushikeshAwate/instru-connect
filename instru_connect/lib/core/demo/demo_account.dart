class DemoAccount {
  static const email = 'appreview.instru@coeptech.ac.in';
  static const password = 'Review@12345';
  static const name = 'App Review Demo';
  static const department = 'Instrumentation Department';
  static const contactNo = '9999999999';
  static const parentContactNo = '9999999998';
  static const misNo = 'DEMO2026';

  static bool isDemoEmail(String? email) {
    return email?.trim().toLowerCase() == DemoAccount.email;
  }
}
