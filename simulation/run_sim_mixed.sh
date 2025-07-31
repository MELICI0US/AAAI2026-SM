for x in {1..10}; do
    dart run ./simulator_mixed.dart $x noFearNoChat
    # dart run ./simulator_mixed.dart $x fearNoChat
    # dart run ./simulator_mixed.dart $x noFearChat
    # dart run ./simulator_mixed.dart $x fearChat
done

