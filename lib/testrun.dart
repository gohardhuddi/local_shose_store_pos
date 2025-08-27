import 'dart:math';

void main() {
  int number = 600851475143;
  List<int> primeFac = [];
  for (int i = 2; i <= sqrt(number); i++) {
    if (number % i == 0) {
      bool prime = isPrime(i);
      if (prime) {
        primeFac.add(i);
      }
    }
  }
  print(primeFac);
}

bool isPrime(int n) {
  if (n <= 1) return false; // 0 and 1 are not prime
  for (int i = 2; i <= sqrt(n); i++) {
    if (n % i == 0) {
      return false; // found a divisor
    }
  }
  return true; // no divisors found
}
