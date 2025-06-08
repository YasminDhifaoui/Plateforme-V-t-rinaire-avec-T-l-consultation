enum Environment { emulator, realDevice }

const Environment currentEnv = Environment.emulator;

class BaseUrl {
  static String get api {
    switch (currentEnv) {
      case Environment.emulator:
        return 'http://10.0.2.2:5000';
      case Environment.realDevice:
        return 'http://192.168.101.102:5000';//storia
    }
  }
}
